import { appendFile, mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

import { fetchKboGameList, fetchKboScheduleList } from '../src/clients/kboClient.js'
import { mapGame } from '../src/mappers/gameMapper.js'
import { indexScheduleGames } from '../src/mappers/scheduleMapper.js'
import type { NormalizedGame } from '../src/models/normalizedGame.js'
import { summarizeGameChanges, toPollingView } from '../src/utils/gameSnapshot.js'
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

async function ensureDir(dirPath: string) {
  await mkdir(dirPath, { recursive: true })
}

async function writeJson(filePath: string, value: unknown) {
  await ensureDir(path.dirname(filePath))
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8')
}

const date = toKboDate(readArg('date'))
const intervalSeconds = Number(readArg('interval', '30'))
const iterations = Number(readArg('iterations', '0'))
const logsDir = readArg('logs-dir', path.resolve('logs/polling', date))!
const fixturesDir = readArg('fixtures-dir', path.resolve('fixtures', date))!
const saveRaw = readBooleanArg('save-raw')
const saveSnapshots = !readBooleanArg('no-save-snapshots')
const captureOnChange = !readBooleanArg('no-capture-on-change')
const scheduleList = await fetchKboScheduleList(date.slice(0, 4), date.slice(4, 6))
const scheduleByGameId = indexScheduleGames(scheduleList)

let previousGames: NormalizedGame[] = []
let runCount = 0

async function tick() {
  const fetchedAt = new Date()
  const raw = await fetchKboGameList(date)
  const normalized = raw.game.map((game) => mapGame(game, scheduleByGameId.get(game.G_ID)))
  const changes = summarizeGameChanges(previousGames, normalized)
  const timestamp = timestampForFile(fetchedAt)

  const payload = {
    fetchedAt: fetchedAt.toISOString(),
    date,
    gameCount: normalized.length,
    changedGames: changes.length,
    changes,
    games: normalized.map(toPollingView)
  }

  console.log(JSON.stringify(payload, null, 2))

  await ensureDir(logsDir)
  await appendFile(path.join(logsDir, 'events.ndjson'), `${JSON.stringify(payload)}\n`, 'utf8')

  if (saveSnapshots) {
    await writeJson(path.join(logsDir, 'snapshots', `${timestamp}.normalized.json`), payload)
  }

  if (saveRaw) {
    await writeJson(path.join(logsDir, 'snapshots', `${timestamp}.raw.json`), {
      fetchedAt: fetchedAt.toISOString(),
      date,
      gameList: raw
    })
  }

  await writeJson(path.join(fixturesDir, 'latest-normalized.json'), payload)

  if (saveRaw) {
    await writeJson(path.join(fixturesDir, 'latest-raw.json'), {
      fetchedAt: fetchedAt.toISOString(),
      date,
      gameList: raw,
      scheduleList
    })
  }

  if (captureOnChange && changes.length > 0) {
    await writeJson(path.join(fixturesDir, 'changes', `${timestamp}.json`), payload)
  }

  previousGames = normalized
  runCount += 1
}

await tick()

if (iterations > 0 && runCount >= iterations) {
  process.exit(0)
}

const timer = setInterval(() => {
  tick()
    .then(() => {
      if (iterations > 0 && runCount >= iterations) {
        clearInterval(timer)
        process.exit(0)
      }
    })
    .catch((error) => {
      console.error('[poll-live-games] tick failed', error)
    })
}, intervalSeconds * 1000)
