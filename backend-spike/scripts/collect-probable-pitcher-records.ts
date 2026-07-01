import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

import { fetchKboGameList, fetchKboPitcherRecordAnalysis } from '../src/clients/kboClient.js'
import { mapProbablePitcherRecordAnalysis, type ProbablePitcherStarter } from '../src/mappers/probablePitcherRecordMapper.js'
import { upsertPitchingSeasonRecords } from '../src/repositories/playerRecordRepository.js'
import { resolveArtifactOutDir } from '../src/records/sourceCollectionUtils.js'
import { toKboDate } from '../src/utils/date.js'
import type { RawKboGame } from '../src/dto/kboGameList.dto.js'
import type { RawKboPitcherRecordAnalysisResponse } from '../src/dto/kboPitcherRecordAnalysis.dto.js'
import type { PitchingLeaderEntry } from '../src/mappers/playerLeaderMapper.js'

const ONE_DAY_MS = 86_400_000

interface CollectedGameSummary {
  readonly gameId: string
  readonly records: readonly {
    readonly playerId: string
    readonly playerName: string
    readonly teamId: string
    readonly wins: number | null
    readonly losses: number | null
    readonly era: number | null
    readonly whip: number | null
  }[]
}

interface SkippedGameSummary {
  readonly gameId: string
  readonly reason: string
}

export interface CollectGameOptions {
  readonly now?: Date
  readonly fetchPitcherRecordAnalysis?: (request: Parameters<typeof fetchKboPitcherRecordAnalysis>[0]) => Promise<RawKboPitcherRecordAnalysisResponse>
}

function readArg(name: string, fallback?: string): string | undefined {
  const prefix = `--${name}`
  const args = process.argv.slice(2)

  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === prefix) {
      return args[i + 1] ?? fallback
    }
  }

  return fallback
}

function readBooleanArg(name: string): boolean {
  return process.argv.slice(2).includes(`--${name}`)
}

function timestampForFile(date = new Date()): string {
  return date.toISOString().replaceAll(':', '-').replaceAll('.', '-')
}

function todayKboDate(date = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).format(date).replaceAll('-', '')
}

function addKboDays(dateKey: string, days: number): string {
  const year = Number(dateKey.slice(0, 4))
  const month = Number(dateKey.slice(4, 6))
  const day = Number(dateKey.slice(6, 8))

  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
    return dateKey
  }

  const date = new Date(Date.UTC(year, month - 1, day) + (days * ONE_DAY_MS))
  return [
    String(date.getUTCFullYear()).padStart(4, '0'),
    String(date.getUTCMonth() + 1).padStart(2, '0'),
    String(date.getUTCDate()).padStart(2, '0')
  ].join('')
}

function readNow(): Date {
  const value = readArg('now')
  if (value == null) {
    return new Date()
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid --now value: ${value}`)
  }

  return date
}

function parseDates(): string[] {
  const explicitDates = readArg('dates')
  const singleDate = readArg('date')

  if (explicitDates) {
    return [...new Set(explicitDates.split(',').map((date) => toKboDate(date.trim())).filter(Boolean))]
  }

  if (singleDate) {
    return [toKboDate(singleDate)]
  }

  return [todayKboDate()]
}

async function writeJson(filePath: string, value: unknown): Promise<void> {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8')
}

function stringValue(value: string | number | null | undefined): string | null {
  if (value == null) {
    return null
  }

  const text = String(value).trim()
  return text === '' ? null : text
}

function starterInput(game: RawKboGame, side: 'away' | 'home'): ProbablePitcherStarter | null {
  const playerId = stringValue(side === 'away' ? game.T_PIT_P_ID : game.B_PIT_P_ID)
  const playerName = stringValue(side === 'away' ? game.T_PIT_P_NM : game.B_PIT_P_NM)
  const teamId = stringValue(side === 'away' ? game.AWAY_ID : game.HOME_ID)
  const teamName = stringValue(side === 'away' ? game.AWAY_NM : game.HOME_NM)

  if (playerId == null || playerName == null || teamId == null || teamName == null) {
    return null
  }

  return {
    side,
    playerId,
    playerName,
    teamId,
    teamName
  }
}

function scheduledGame(game: RawKboGame): boolean {
  return stringValue(game.GAME_STATE_SC) === '1'
}

function starterNotDue(game: RawKboGame, now: Date): boolean {
  const gameDate = stringValue(game.G_DT)
  if (gameDate == null) {
    return false
  }

  return gameDate > addKboDays(todayKboDate(now), 1)
}

function requestInput(game: RawKboGame, away: ProbablePitcherStarter, home: ProbablePitcherStarter) {
  const leId = stringValue(game.LE_ID) ?? '1'
  const srId = stringValue(game.SR_ID) ?? '0'
  const seasonId = stringValue(game.SEASON_ID) ?? stringValue(game.G_DT)?.slice(0, 4)
  const gameId = stringValue(game.G_ID)

  if (seasonId == null || gameId == null) {
    return null
  }

  return {
    leId,
    srId,
    seasonId,
    awayTeamId: away.teamId,
    awayPitId: away.playerId,
    homeTeamId: home.teamId,
    homePitId: home.playerId,
    gameId
  }
}

function recordSummary(record: PitchingLeaderEntry): CollectedGameSummary['records'][number] {
  return {
    playerId: record.playerId,
    playerName: record.playerName,
    teamId: record.teamId,
    wins: record.wins,
    losses: record.losses,
    era: record.era,
    whip: record.whip ?? null
  }
}

export async function collectGame(game: RawKboGame, options: CollectGameOptions = {}): Promise<CollectedGameSummary | SkippedGameSummary> {
  const gameId = stringValue(game.G_ID) ?? 'unknown'
  const now = options.now ?? new Date()
  if (starterNotDue(game, now)) {
    return { gameId, reason: 'starter not due' }
  }

  const away = starterInput(game, 'away')
  const home = starterInput(game, 'home')

  if (away == null || home == null) {
    return { gameId, reason: 'missing starter id or name' }
  }

  const request = requestInput(game, away, home)
  if (request == null) {
    return { gameId, reason: 'missing game id or season id' }
  }

  const fetchPitcherRecordAnalysis = options.fetchPitcherRecordAnalysis ?? fetchKboPitcherRecordAnalysis
  const response = await fetchPitcherRecordAnalysis(request)
  const records = mapProbablePitcherRecordAnalysis({
    response,
    starters: [away, home]
  })
  const date = stringValue(game.G_DT) ?? request.seasonId
  upsertPitchingSeasonRecords(date, records)

  return {
    gameId,
    records: records.map(recordSummary)
  }
}

async function main(): Promise<void> {
  const dates = parseDates()
  const now = readNow()
  const shouldWrite = readBooleanArg('write')
  const runId = readArg('run-id', timestampForFile()) ?? timestampForFile()
  const artifactRoot = path.resolve('artifacts', 'probable-pitcher-records')
  const outDir = resolveArtifactOutDir(artifactRoot, runId, readArg('out-dir'))
  const collected: CollectedGameSummary[] = []
  const skipped: SkippedGameSummary[] = []

  for (const date of dates) {
    const gameList = await fetchKboGameList(date)
    const scheduledGames = gameList.game.filter(scheduledGame)

    for (const game of scheduledGames) {
      const result = await collectGame(game, { now })
      if ('records' in result) {
        collected.push(result)
      } else {
        skipped.push(result)
      }
    }
  }

  const manifest = {
    runId,
    collectedAt: new Date().toISOString(),
    dates,
    outDir: shouldWrite ? path.relative(process.cwd(), outDir) : null,
    collectedGames: collected.length,
    records: collected.reduce((count, game) => count + game.records.length, 0),
    skippedGames: skipped.length,
    games: collected,
    skipped
  }

  console.log(JSON.stringify(manifest, null, 2))

  if (shouldWrite) {
    await writeJson(path.join(outDir, 'manifest.json'), manifest)
  }
}

const scriptPath = process.argv[1]
if (scriptPath != null && import.meta.url === pathToFileURL(path.resolve(scriptPath)).href) {
  await main()
}
