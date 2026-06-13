import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

import { fetchKboGameDate, fetchKboGameList, fetchKboScheduleList } from '../src/clients/kboClient.js'
import { mapGame } from '../src/mappers/gameMapper.js'
import { indexScheduleGames, mapScheduleGames } from '../src/mappers/scheduleMapper.js'
import { toPollingView } from '../src/utils/gameSnapshot.js'
import { toKboDate } from '../src/utils/date.js'

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

async function writeJson(filePath: string, value: unknown) {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8')
}

const date = toKboDate(readArg('date'))
const seasonId = date.slice(0, 4)
const gameMonth = date.slice(4, 6)
const outDir = readArg('out-dir', path.resolve('fixtures', date, 'dump'))!
const shouldWrite = readBooleanArg('write')
const fetchedAt = new Date().toISOString()

const [gameDate, gameList, scheduleList] = await Promise.all([
  fetchKboGameDate(date),
  fetchKboGameList(date),
  fetchKboScheduleList(seasonId, gameMonth)
])

const scheduleByGameId = indexScheduleGames(scheduleList)
const scheduleGames = mapScheduleGames(scheduleList).filter((game) => game.date === date)
const normalized = gameList.game.map((game) => mapGame(game, scheduleByGameId.get(game.G_ID)))
const payload = {
  requestedDate: date,
  fetchedAt,
  gameDate,
  gameList,
  scheduleList,
  scheduleGames,
  normalizedGames: normalized,
  pollingView: normalized.map(toPollingView)
}

console.log(JSON.stringify(payload, null, 2))

if (shouldWrite) {
  const timestamp = timestampForFile()
  await writeJson(path.join(outDir, `${timestamp}.json`), payload)
  await writeJson(path.join(outDir, 'latest.json'), payload)
}
