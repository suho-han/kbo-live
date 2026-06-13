import { describe, expect, it } from 'vitest'

import { fetchKboGameDate, fetchKboGameList, fetchKboScheduleList } from '../src/clients/kboClient.js'
import { mapGame } from '../src/mappers/gameMapper.js'
import { indexScheduleGames } from '../src/mappers/scheduleMapper.js'
import { toKboDate } from '../src/utils/date.js'
import { TEST_DATE } from './testConfig.js'

describe('live KBO source smoke', () => {
  it('loads and normalizes a known completed date from the live KBO endpoints', async () => {
    const date = toKboDate(TEST_DATE)
    const [gameDate, gameList, scheduleList] = await Promise.all([
      fetchKboGameDate(date),
      fetchKboGameList(date),
      fetchKboScheduleList(date.slice(0, 4), date.slice(4, 6))
    ])
    const scheduleByGameId = indexScheduleGames(scheduleList)
    const normalized = gameList.game.map((game) => mapGame(game, scheduleByGameId.get(game.G_ID)))

    expect(gameDate.NOW_G_DT).toMatch(/^\d{8}$/)
    expect(gameList.game.length).toBeGreaterThan(0)
    expect(scheduleList.rows.length).toBeGreaterThan(0)
    expect(normalized.length).toBe(gameList.game.length)
    expect(normalized[0].gameId).not.toBe('')
    expect(normalized[0].awayTeam.name).not.toBe('')
    expect(normalized[0].homeTeam.name).not.toBe('')
  }, 20_000)
})
