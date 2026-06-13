import { readdirSync } from 'node:fs'
import path from 'node:path'

function latestCompletedFixtureDate(): string {
  return readdirSync(path.resolve('fixtures/202606-completed'), { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && /^\d{8}$/.test(entry.name))
    .map((entry) => entry.name)
    .sort()
    .at(-1) ?? ''
}

export const TEST_DATE = process.env.TEST_DATE ?? latestCompletedFixtureDate()
export const TEST_INPUT_DATE = `${TEST_DATE.slice(0, 4)}-${TEST_DATE.slice(4, 6)}-${TEST_DATE.slice(6, 8)}`
export const TEST_MONTH = TEST_DATE.slice(4, 6)
export const TEST_SEASON = TEST_DATE.slice(0, 4)
export const TEST_GAME_ID = `${TEST_DATE}LTLG0`
export const TEST_START_TIME = `${TEST_DATE}T17:00:00+09:00`
export const TEST_FIXTURE_PATH = `fixtures/202606-completed/${TEST_DATE}/latest.json`

function addDays(date: string, days: number): string {
  const value = new Date(Date.UTC(
    Number(date.slice(0, 4)),
    Number(date.slice(4, 6)) - 1,
    Number(date.slice(6, 8)) + days
  ))

  return value.toISOString().slice(0, 10).replaceAll('-', '')
}

export const TEST_KOREA_ROLLOVER_INSTANT = new Date(`${TEST_INPUT_DATE}T18:00:00.000Z`)
export const TEST_NEXT_DATE = addDays(TEST_DATE, 1)
