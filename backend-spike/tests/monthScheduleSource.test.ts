import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('../src/clients/kboClient.js', () => ({
  fetchKboGameDate: vi.fn(),
  fetchKboGameList: vi.fn(),
  fetchKboLiveTextView: vi.fn(),
  fetchKboScheduleList: vi.fn(),
  fetchKboTeamRankDailyPage: vi.fn()
}))

import { loadKboMonthGameSource } from '../src/services/monthScheduleSource.js'
import {
  buildMonthGameList,
  buildMonthScheduleList,
  cleanupGameServiceTestState,
  mockGameList,
  mockScheduleList,
  resetGameServiceTestState,
  TEST_DATE,
  TEST_GAME_ID,
  TEST_NEXT_DATE
} from './gameServiceTestSupport.js'

describe('monthScheduleSource', () => {
  const tempDirs: string[] = []

  beforeEach(() => {
    resetGameServiceTestState()
  })

  afterEach(() => {
    cleanupGameServiceTestState(tempDirs)
  })

  it('normalizes schedule-only games when the requested day GameList is empty', async () => {
    const { nextGameId, scheduleList } = buildMonthScheduleList()
    mockScheduleList.mockResolvedValue(scheduleList)
    mockGameList.mockImplementation(async (date) => (
      date === TEST_DATE ? { game: [] } : buildMonthGameList(date, nextGameId)
    ))

    const result = await loadKboMonthGameSource(TEST_DATE)

    expect(mockGameList).toHaveBeenCalledWith(TEST_DATE)
    expect(mockGameList).toHaveBeenCalledWith(TEST_NEXT_DATE)
    expect(result.requestedGameList.game).toEqual([])
    expect(result.scheduleGames.map((game) => game.date)).toEqual([TEST_DATE, TEST_NEXT_DATE])
    expect(result.normalizedGames.map((game) => game.gameId)).toEqual([TEST_GAME_ID, nextGameId])
    expect(result.normalizedGames.find((game) => game.gameId === TEST_GAME_ID)).toMatchObject({
      date: TEST_DATE,
      status: 'scheduled',
      venue: '잠실'
    })
  })
})
