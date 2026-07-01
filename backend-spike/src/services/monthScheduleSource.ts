import { fetchKboGameDate, fetchKboGameList, fetchKboScheduleList } from '../clients/kboClient.js'
import { mapGame, mapScheduledGame } from '../mappers/gameMapper.js'
import { mapScheduleGames } from '../mappers/scheduleMapper.js'
import type { RawKboGameDateResponse } from '../dto/kboGameDate.dto.js'
import type { RawKboGameListResponse } from '../dto/kboGameList.dto.js'
import type { RawKboScheduleListResponse } from '../dto/kboScheduleList.dto.js'
import type { NormalizedGame } from '../models/normalizedGame.js'
import type { ScheduleGameInfo } from '../mappers/scheduleMapper.js'

export interface MonthGameListSource {
  readonly date: string
  readonly gameList: RawKboGameListResponse
}

export interface KboMonthGameSource {
  readonly gameDate: RawKboGameDateResponse
  readonly requestedGameList: RawKboGameListResponse
  readonly gameLists: readonly MonthGameListSource[]
  readonly scheduleList: RawKboScheduleListResponse
  readonly scheduleGames: readonly ScheduleGameInfo[]
  readonly normalizedGames: readonly NormalizedGame[]
}

function sortGames(games: Iterable<NormalizedGame>): NormalizedGame[] {
  return [...games].sort((lhs, rhs) => {
    const lhsStart = lhs.startTime ?? lhs.date
    const rhsStart = rhs.startTime ?? rhs.date
    if (lhsStart !== rhsStart) {
      return lhsStart.localeCompare(rhsStart)
    }

    return lhs.gameId.localeCompare(rhs.gameId)
  })
}

export async function loadKboMonthGameSource(kboDate: string): Promise<KboMonthGameSource> {
  const [gameDate, scheduleList] = await Promise.all([
    fetchKboGameDate(kboDate),
    fetchKboScheduleList(kboDate.slice(0, 4), kboDate.slice(4, 6))
  ])
  const scheduleGames = mapScheduleGames(scheduleList, kboDate.slice(0, 4))
    .filter((game) => game.date.startsWith(kboDate.slice(0, 6)))
  const scheduleByGameId = new Map(scheduleGames.map((game) => [game.gameId, game]))
  const dates = [...new Set([kboDate, ...scheduleGames.map((game) => game.date)])].sort()
  const gameLists = await Promise.all(
    dates.map(async (date) => ({
      date,
      gameList: await fetchKboGameList(date)
    }))
  )
  const requestedGameList = gameLists.find((entry) => entry.date === kboDate)?.gameList ?? { game: [] }

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

  return {
    gameDate,
    requestedGameList,
    gameLists,
    scheduleList,
    scheduleGames,
    normalizedGames: sortGames(gamesById.values())
  }
}
