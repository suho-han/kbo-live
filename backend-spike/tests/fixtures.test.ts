import { readFileSync } from 'node:fs'
import path from 'node:path'
import { describe, expect, it } from 'vitest'

import { mapGame } from '../src/mappers/gameMapper.js'
import { indexScheduleGames, mapScheduleGames } from '../src/mappers/scheduleMapper.js'
import type { RawKboGameListResponse } from '../src/dto/kboGameList.dto.js'
import type { RawKboScheduleListResponse } from '../src/dto/kboScheduleList.dto.js'
import { TEST_DATE, TEST_FIXTURE_PATH, TEST_GAME_ID, TEST_START_TIME } from './testConfig.js'

describe('completed game fixtures', () => {
  it('normalizes the configured completed KBO dump with schedule metadata', () => {
    const fixture = JSON.parse(readFileSync(path.resolve(TEST_FIXTURE_PATH), 'utf8')) as {
      requestedDate: string
      gameList: RawKboGameListResponse
      scheduleList: RawKboScheduleListResponse
    }
    const scheduleByGameId = indexScheduleGames(fixture.scheduleList)
    const scheduleGames = mapScheduleGames(fixture.scheduleList).filter((game) => game.date === fixture.requestedDate)
    const normalized = fixture.gameList.game.map((game) => mapGame(game, scheduleByGameId.get(game.G_ID)))

    expect(fixture.requestedDate).toBe(TEST_DATE)
    expect(fixture.gameList.game).toHaveLength(5)
    expect(scheduleGames).toHaveLength(5)
    expect(normalized).toHaveLength(5)
    expect(normalized.every((game) => game.status === 'final')).toBe(true)
    expect(normalized.every((game) => game.startTime?.startsWith(`${TEST_DATE}T`))).toBe(true)
    expect(normalized.every((game) => game.venue !== null)).toBe(true)
    expect(normalized[0]).toMatchObject({
      gameId: TEST_GAME_ID,
      venue: '잠실',
      startTime: TEST_START_TIME,
      broadcastChannels: ['SPO-2T'],
      homepageLinks: {
        review: expect.stringContaining('section=REVIEW'),
        highlight: expect.stringContaining('section=HIGHLIGHT')
      }
    })
  })
})
