import { fetchKboGameDate, fetchKboGameList, fetchKboScheduleList, fetchKboTeamRankDailyPage } from '../clients/kboClient.js'
import { makeTestLiveGame } from '../fixtures/testLiveGame.js'
import { mapGame, mapScheduledGame } from '../mappers/gameMapper.js'
import { mapScheduleGames } from '../mappers/scheduleMapper.js'
import { parseKboTeamRankDaily } from '../mappers/teamRankMapper.js'
import { listTeamSeasonRecords, upsertTeamSeasonRecords } from '../repositories/teamRecordRepository.js'
import { enrichPreviousAtBatResult } from './liveTextEnrichment.js'
import { enrichTeamRecords, teamRecordsById } from './teamRecordEnrichment.js'
import { toKboDate } from '../utils/date.js'
import type { TeamRankEntry } from '../mappers/teamRankMapper.js'
import type { NormalizedGame } from '../models/normalizedGame.js'
import type { TeamSeasonRecord } from '../repositories/teamRecordRepository.js'

interface TodayGamesResult {
  date: string
  games: NormalizedGame[]
}

interface TodayGamesCacheEntry {
  value: TodayGamesResult
  expiresAt: number
  staleUntil: number
}

const todayGamesCache = new Map<string, TodayGamesCacheEntry>()
const todayGamesInFlight = new Map<string, Promise<TodayGamesResult>>()
const teamRankCache = new Map<string, {
  value: TeamRankEntry[]
  expiresAt: number
}>()

function envNumber(name: string, fallback: number): number {
  const value = process.env[name]
  if (value === undefined) {
    return fallback
  }

  const parsed = Number(value)
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback
}

function gameCacheTtlSeconds(games: NormalizedGame[]): number {
  if (games.some((game) => game.status === 'live')) {
    return envNumber('KBO_CACHE_TTL_GAME_LIVE_SEC', 5)
  }

  return envNumber('KBO_CACHE_TTL_GAME_IDLE_SEC', 60)
}

function staleIfErrorSeconds(): number {
  return envNumber('KBO_CACHE_STALE_IF_ERROR_SEC', 600)
}

function teamRankCacheTtlSeconds(): number {
  return envNumber('KBO_CACHE_TTL_STANDINGS_SEC', 600)
}

function teamRankEntriesFromDb(records: TeamSeasonRecord[]): TeamRankEntry[] {
  return records.map((record) => ({
    teamId: record.teamId,
    teamName: record.teamName,
    wins: record.wins ?? 0,
    losses: record.losses ?? 0,
    draws: record.draws ?? 0,
    rank: record.rank,
    streak: record.streak,
    winRate: record.winningPercentage == null ? null : String(record.winningPercentage),
    recentTen: record.recent10,
    gamesBack: record.gamesBehind
  }))
}

function loadTeamStandingsEntriesFromDb(kboDate: string): TeamRankEntry[] {
  try {
    return teamRankEntriesFromDb(listTeamSeasonRecords(kboDate))
  } catch {
    return []
  }
}

async function loadTeamStandingsEntries(kboDate: string): Promise<TeamRankEntry[]> {
  const cached = teamRankCache.get(kboDate)
  const now = Date.now()
  if (cached && cached.expiresAt > now) {
    return cached.value
  }

  try {
    const html = await fetchKboTeamRankDailyPage(kboDate)
    const standings = parseKboTeamRankDaily(html)
      .sort((lhs, rhs) => (lhs.rank ?? Number.MAX_SAFE_INTEGER) - (rhs.rank ?? Number.MAX_SAFE_INTEGER))
    try {
      upsertTeamSeasonRecords(kboDate, standings)
    } catch {
      // DB persistence must not break the live source response path.
    }

    teamRankCache.set(kboDate, {
      value: standings,
      expiresAt: now + teamRankCacheTtlSeconds() * 1000
    })

    return standings
  } catch {
    return cached?.value ?? loadTeamStandingsEntriesFromDb(kboDate)
  }
}

async function loadMonthGames(kboDate: string) {
  const [gameDate, scheduleList] = await Promise.all([
    fetchKboGameDate(kboDate),
    fetchKboScheduleList(kboDate.slice(0, 4), kboDate.slice(4, 6))
  ])
  const scheduleGames = mapScheduleGames(scheduleList)
    .filter((game) => game.date.startsWith(kboDate.slice(0, 6)))
  const scheduleByGameId = new Map(scheduleGames.map((game) => [game.gameId, game]))
  const dates = [...new Set([kboDate, ...scheduleGames.map((game) => game.date)])].sort()
  const gameLists = await Promise.all(
    dates.map(async (date) => ({
      date,
      gameList: await fetchKboGameList(date)
    }))
  )

  const gamesById = new Map<string, NormalizedGame>()
  for (const { gameList } of gameLists) {
    for (const game of gameList.game) {
      gamesById.set(game.G_ID, mapGame(game, scheduleByGameId.get(game.G_ID)))
    }
  }

  for (const scheduleGame of scheduleGames) {
    if (!gamesById.has(scheduleGame.gameId)) {
      gamesById.set(scheduleGame.gameId, mapScheduledGame(scheduleGame))
    }
  }

  const enrichedGames = await Promise.all(
    [...gamesById.values()].map((game) => enrichPreviousAtBatResult(game, kboDate))
  )

  const teamRecords = teamRecordsById(await loadTeamStandingsEntries(kboDate))
  const games = enrichedGames
    .map((game) => enrichTeamRecords(game, teamRecords))
    .sort((lhs, rhs) => {
      const lhsStart = lhs.startTime ?? lhs.date
      const rhsStart = rhs.startTime ?? rhs.date
      if (lhsStart !== rhsStart) {
        return lhsStart.localeCompare(rhsStart)
      }

      return lhs.gameId.localeCompare(rhs.gameId)
    })

  return {
    gameDate,
    scheduleList,
    scheduleGames,
    gameLists,
    games
  }
}

export async function getTodayGames(date?: string) {
  const kboDate = toKboDate(date)

  if (process.env.KBO_USE_TEST_LIVE_GAME === '1') {
    return {
      date: kboDate,
      games: [makeTestLiveGame(kboDate)]
    }
  }

  const now = Date.now()
  const cached = todayGamesCache.get(kboDate)
  if (cached && cached.expiresAt > now) {
    return cached.value
  }

  const inFlight = todayGamesInFlight.get(kboDate)
  if (inFlight) {
    return inFlight
  }

  const request = (async (): Promise<TodayGamesResult> => {
    try {
      const { games } = await loadMonthGames(kboDate)
      const value = {
        date: kboDate,
        games
      }
      const cacheTtlMs = gameCacheTtlSeconds(games) * 1000
      const staleTtlMs = staleIfErrorSeconds() * 1000
      const writtenAt = Date.now()

      todayGamesCache.set(kboDate, {
        value,
        expiresAt: writtenAt + cacheTtlMs,
        staleUntil: writtenAt + cacheTtlMs + staleTtlMs
      })

      return value
    } catch (error) {
      const stale = todayGamesCache.get(kboDate)
      if (stale && stale.staleUntil > Date.now()) {
        return stale.value
      }

      throw error
    } finally {
      todayGamesInFlight.delete(kboDate)
    }
  })()

  todayGamesInFlight.set(kboDate, request)
  return request
}

export async function getGameById(gameId: string, date?: string) {
  const result = await getTodayGames(date)
  return {
    date: result.date,
    game: result.games.find((game) => game.gameId === gameId) ?? null
  }
}

export async function getTeamStandings(date?: string) {
  const kboDate = toKboDate(date)
  return {
    date: kboDate,
    standings: await loadTeamStandingsEntries(kboDate)
  }
}

export async function getTodayGamesRaw(date?: string) {
  const kboDate = toKboDate(date)

  if (process.env.KBO_USE_TEST_LIVE_GAME === '1') {
    const game = makeTestLiveGame(kboDate)

    return {
      requestedDate: kboDate,
      gameDate: null,
      gameList: { game: [] },
      gameLists: [],
      scheduleList: { rows: [] },
      scheduleGames: [],
      normalizedGames: [game]
    }
  }

  const { gameDate, scheduleList, scheduleGames, gameLists, games } = await loadMonthGames(kboDate)
  const requestedGameList = gameLists.find((entry) => entry.date === kboDate)?.gameList ?? { game: [] }

  return {
    requestedDate: kboDate,
    gameDate,
    gameList: requestedGameList,
    gameLists,
    scheduleList,
    scheduleGames,
    normalizedGames: games
  }
}

export function clearGameServiceCacheForTests() {
  todayGamesCache.clear()
  todayGamesInFlight.clear()
  teamRankCache.clear()
}
