import { mkdtempSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('../src/clients/kboClient.js', () => ({
  fetchKboGameDate: vi.fn(),
  fetchKboGameList: vi.fn(),
  fetchKboLiveTextView: vi.fn(),
  fetchKboScheduleList: vi.fn(),
  fetchKboTeamRankDailyPage: vi.fn()
}))

import type { RawKboScheduleListResponse } from '../src/dto/kboScheduleList.dto.js'
import { upsertTeamSeasonRecords } from '../src/repositories/teamRecordRepository.js'
import { getTeamStandings, getTodayGames } from '../src/services/gameService.js'
import {
  buildMonthGameList,
  buildMonthScheduleList,
  cleanupGameServiceTestState,
  mockGameDate,
  mockGameList,
  mockScheduleList,
  mockTeamRankDailyPage,
  resetGameServiceTestState,
  TEST_DATE,
  TEST_INPUT_DATE,
  TEST_NEXT_DATE
} from './gameServiceTestSupport.js'

describe('gameService cache', () => {
  const tempDirs: string[] = []

  beforeEach(() => {
    resetGameServiceTestState()
  })

  afterEach(() => {
    cleanupGameServiceTestState(tempDirs)
  })

  it('serves repeated today requests from cache while the cache is fresh', async () => {
    process.env.KBO_CACHE_TTL_GAME_IDLE_SEC = '60'

    const first = await getTodayGames(TEST_INPUT_DATE)
    const second = await getTodayGames(TEST_INPUT_DATE)

    expect(second).toEqual(first)
    expect(mockGameDate).toHaveBeenCalledTimes(1)
    expect(mockScheduleList).toHaveBeenCalledTimes(1)
    expect(mockGameList).toHaveBeenCalledTimes(1)
    expect(mockTeamRankDailyPage).toHaveBeenCalledTimes(1)
  })

  it('deduplicates concurrent today requests for the same date', async () => {
    let resolveSchedule: (value: RawKboScheduleListResponse) => void = () => {}
    const pendingSchedule = new Promise<RawKboScheduleListResponse>((resolve) => {
      resolveSchedule = resolve
    })
    mockScheduleList.mockReturnValue(pendingSchedule)

    const first = getTodayGames(TEST_INPUT_DATE)
    const second = getTodayGames(TEST_INPUT_DATE)

    resolveSchedule({
      rows: [{
        row: [
          { Text: '06.13(토)', Class: 'day' },
          { Text: '<b>17:00</b>', Class: 'time' },
          { Text: '<span>롯데</span><em><span>vs</span></em><span>LG</span>', Class: 'play' },
          { Text: `<a href='/Schedule/GameCenter/Main.aspx?gameDate=${TEST_DATE}&gameId=${TEST_DATE}LTLG0&section=REVIEW'>리뷰</a>`, Class: 'relay' },
          { Text: '', Class: null },
          { Text: 'SPO-2T', Class: null },
          { Text: '', Class: null },
          { Text: '잠실', Class: null },
          { Text: '-', Class: null }
        ]
      }]
    })

    const [firstResult, secondResult] = await Promise.all([first, second])

    expect(secondResult).toEqual(firstResult)
    expect(mockGameDate).toHaveBeenCalledTimes(1)
    expect(mockScheduleList).toHaveBeenCalledTimes(1)
    expect(mockGameList).toHaveBeenCalledTimes(1)
  })

  it('returns stale cached games when the source fails inside the stale window', async () => {
    process.env.KBO_CACHE_TTL_GAME_IDLE_SEC = '0'
    process.env.KBO_CACHE_STALE_IF_ERROR_SEC = '600'
    const cached = await getTodayGames(TEST_INPUT_DATE)

    mockGameDate.mockRejectedValue(new Error('source down'))

    const fallback = await getTodayGames(TEST_INPUT_DATE)

    expect(fallback).toEqual(cached)
    expect(mockGameDate).toHaveBeenCalledTimes(2)
  })

  it('falls back to DB-backed team standings when the source fails and cache is empty', async () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-standings-fallback-'))
    tempDirs.push(dir)
    process.env.BASEBALL_LIVE_KR_DB_PATH = join(dir, 'test.sqlite')
    upsertTeamSeasonRecords(TEST_DATE, [{
      teamId: 'LG',
      teamName: 'LG',
      rank: 1,
      wins: 41,
      losses: 24,
      draws: 0,
      winRate: '0.631',
      gamesBack: '0',
      recentTen: '7승0무3패',
      streak: '2승'
    }])
    mockTeamRankDailyPage.mockRejectedValue(new Error('source down'))

    const result = await getTeamStandings(TEST_INPUT_DATE)

    expect(result).toMatchObject({
      date: TEST_DATE,
      standings: [{
        teamId: 'LG',
        teamName: 'LG',
        rank: 1,
        wins: 41,
        losses: 24,
        draws: 0,
        streak: '2승'
      }]
    })
  })

  it('loads every scheduled date in the month instead of only the requested date', async () => {
    const { nextGameId, scheduleList } = buildMonthScheduleList()
    mockScheduleList.mockResolvedValue(scheduleList)
    mockGameList.mockImplementation(async (date) => buildMonthGameList(date, nextGameId))

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(mockGameList).toHaveBeenCalledWith(TEST_DATE)
    expect(mockGameList).toHaveBeenCalledWith(TEST_NEXT_DATE)
    expect(result.games.map((game) => game.gameId)).toEqual([`${TEST_DATE}LTLG0`, nextGameId])
    expect(result.games[1]).toMatchObject({
      date: TEST_NEXT_DATE,
      venue: '대구',
      broadcastChannels: ['KBSN']
    })
  })
})
