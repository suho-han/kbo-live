import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { fetchKboGameDate, fetchKboGameList, fetchKboLiveTextView, fetchKboScheduleList, fetchKboTeamRankDailyPage } from '../src/clients/kboClient.js'
import { closeDatabase } from '../src/db/database.js'
import { upsertTeamSeasonRecords } from '../src/repositories/teamRecordRepository.js'
import { clearGameServiceCacheForTests, getGameById, getTeamStandings, getTodayGames, getTodayGamesRaw } from '../src/services/gameService.js'
import { TEST_DATE, TEST_GAME_ID, TEST_INPUT_DATE, TEST_MONTH, TEST_NEXT_DATE, TEST_SEASON, TEST_START_TIME } from './testConfig.js'

vi.mock('../src/clients/kboClient.js', () => ({
  fetchKboGameDate: vi.fn(),
  fetchKboGameList: vi.fn(),
  fetchKboLiveTextView: vi.fn(),
  fetchKboScheduleList: vi.fn(),
  fetchKboTeamRankDailyPage: vi.fn()
}))

const mockGameDate = vi.mocked(fetchKboGameDate)
const mockGameList = vi.mocked(fetchKboGameList)
const mockLiveTextView = vi.mocked(fetchKboLiveTextView)
const mockScheduleList = vi.mocked(fetchKboScheduleList)
const mockTeamRankDailyPage = vi.mocked(fetchKboTeamRankDailyPage)
const tempDirs: string[] = []

const teamRankHtml = `
<table summary="순위, 팀명,승,패,무,승률,승차,최근10경기,연속,홈,방문" class="tData">
  <tbody>
    <tr><td>1</td><td>LG</td><td>65</td><td>41</td><td>24</td><td>0</td><td>0.631</td><td>0</td><td>7승0무3패</td><td>2승</td><td>24-0-11</td><td>17-0-13</td></tr>
    <tr><td>10</td><td>롯데</td><td>64</td><td>24</td><td>39</td><td>1</td><td>0.381</td><td>16</td><td>2승0무8패</td><td>2패</td><td>9-0-22</td><td>15-1-17</td></tr>
  </tbody>
</table>`

describe('gameService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    clearGameServiceCacheForTests()
    delete process.env.KBO_USE_TEST_LIVE_GAME
    delete process.env.KBO_CACHE_TTL_GAME_IDLE_SEC
    delete process.env.KBO_CACHE_TTL_GAME_LIVE_SEC
    delete process.env.KBO_CACHE_STALE_IF_ERROR_SEC
    delete process.env.KBO_DB_ENABLED
    delete process.env.KBO_DB_PATH
    mockGameDate.mockResolvedValue({
      BEFORE_G_DT: '20260612',
      NOW_G_DT: TEST_DATE,
      NOW_G_DT_TEXT: '06.13(토)',
      AFTER_G_DT: '20260614',
      code: '100',
      msg: 'OK'
    })
    mockGameList.mockResolvedValue({
      game: [{
        G_ID: TEST_GAME_ID,
        G_DT: TEST_DATE,
        G_TM: null,
        S_NM: null,
        AWAY_ID: 'LT',
        HOME_ID: 'LG',
        AWAY_NM: '롯데',
        HOME_NM: 'LG',
        GAME_STATE_SC: '3',
        T_SCORE_CN: 3,
        B_SCORE_CN: 5
      }]
    })
    mockScheduleList.mockResolvedValue({
      rows: [{
        row: [
          { Text: '06.13(토)', Class: 'day' },
          { Text: '<b>17:00</b>', Class: 'time' },
          { Text: '<span>롯데</span><em><span>vs</span></em><span>LG</span>', Class: 'play' },
          { Text: `<a href='/Schedule/GameCenter/Main.aspx?gameDate=${TEST_DATE}&gameId=${TEST_GAME_ID}&section=REVIEW'>리뷰</a>`, Class: 'relay' },
          { Text: '', Class: null },
          { Text: 'SPO-2T', Class: null },
          { Text: '', Class: null },
          { Text: '잠실', Class: null },
          { Text: '-', Class: null }
        ]
      }]
    })
    mockTeamRankDailyPage.mockResolvedValue(teamRankHtml)
    mockLiveTextView.mockResolvedValue('')
  })

  afterEach(() => {
    clearGameServiceCacheForTests()
    delete process.env.KBO_USE_TEST_LIVE_GAME
    delete process.env.KBO_CACHE_TTL_GAME_IDLE_SEC
    delete process.env.KBO_CACHE_TTL_GAME_LIVE_SEC
    delete process.env.KBO_CACHE_STALE_IF_ERROR_SEC
    delete process.env.KBO_DB_ENABLED
    delete process.env.KBO_DB_PATH
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
  })

  it('loads source endpoints in KBO date format and enriches games with schedule metadata', async () => {
    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(mockGameDate).toHaveBeenCalledWith(TEST_DATE)
    expect(mockGameList).toHaveBeenCalledWith(TEST_DATE)
    expect(mockScheduleList).toHaveBeenCalledWith(TEST_SEASON, TEST_MONTH)
    expect(result.date).toBe(TEST_DATE)
    expect(result.games).toHaveLength(1)
    expect(result.games[0].venue).toBe('잠실')
    expect(result.games[0].startTime).toBe(TEST_START_TIME)
    expect(result.games[0].broadcastChannels).toEqual(['SPO-2T'])
    expect(result.games[0].homepageLinks.review).toContain('section=REVIEW')
    expect(result.games[0].teamRecords?.away).toMatchObject({ wins: 24, losses: 39, draws: 1, rank: 10, streak: '2패' })
    expect(result.games[0].teamRecords?.home).toMatchObject({ wins: 41, losses: 24, draws: 0, rank: 1, streak: '2승' })
  })

  it('returns a single live fixture game when test live mode is enabled', async () => {
    process.env.KBO_USE_TEST_LIVE_GAME = '1'

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(mockGameDate).not.toHaveBeenCalled()
    expect(mockGameList).not.toHaveBeenCalled()
    expect(mockScheduleList).not.toHaveBeenCalled()
    expect(mockTeamRankDailyPage).not.toHaveBeenCalled()
    expect(result.date).toBe(TEST_DATE)
    expect(result.games).toHaveLength(1)
    expect(result.games[0]).toMatchObject({
      gameId: `${TEST_DATE}LTHH0`,
      status: 'live',
      score: {
        away: 12,
        home: 9
      },
      inning: {
        number: 7,
        half: 'bottom'
      }
    })
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
    let resolveSchedule: (value: Awaited<ReturnType<typeof fetchKboScheduleList>>) => void = () => {}
    const pendingSchedule = new Promise<Awaited<ReturnType<typeof fetchKboScheduleList>>>((resolve) => {
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
          { Text: `<a href='/Schedule/GameCenter/Main.aspx?gameDate=${TEST_DATE}&gameId=${TEST_GAME_ID}&section=REVIEW'>리뷰</a>`, Class: 'relay' },
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
    process.env.KBO_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-standings-fallback-'))
    tempDirs.push(dir)
    process.env.KBO_DB_PATH = join(dir, 'test.sqlite')
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
    clearGameServiceCacheForTests()
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
    const nextGameId = `${TEST_NEXT_DATE}SKSS0`
    mockScheduleList.mockResolvedValue({
      rows: [
        {
          row: [
            { Text: '06.13(토)', Class: 'day' },
            { Text: '<b>17:00</b>', Class: 'time' },
            { Text: '<span>롯데</span><em><span>vs</span></em><span>LG</span>', Class: 'play' },
            { Text: `<a href='/Schedule/GameCenter/Main.aspx?gameDate=${TEST_DATE}&gameId=${TEST_GAME_ID}&section=REVIEW'>리뷰</a>`, Class: 'relay' },
            { Text: '', Class: null },
            { Text: 'SPO-2T', Class: null },
            { Text: '', Class: null },
            { Text: '잠실', Class: null },
            { Text: '-', Class: null }
          ]
        },
        {
          row: [
            { Text: '06.14(일)', Class: 'day' },
            { Text: '<b>18:30</b>', Class: 'time' },
            { Text: '<span>SSG</span><em><span>vs</span></em><span>삼성</span>', Class: 'play' },
            { Text: `<a href='/Schedule/GameCenter/Main.aspx?gameDate=${TEST_NEXT_DATE}&gameId=${nextGameId}&section=START_PIT'>프리뷰</a>`, Class: 'relay' },
            { Text: '', Class: null },
            { Text: 'KBSN', Class: null },
            { Text: '', Class: null },
            { Text: '대구', Class: null },
            { Text: '-', Class: null }
          ]
        }
      ]
    })
    mockGameList.mockImplementation(async (date) => ({
      game: [{
        G_ID: date === TEST_DATE ? TEST_GAME_ID : nextGameId,
        G_DT: date,
        G_TM: null,
        S_NM: null,
        AWAY_ID: date === TEST_DATE ? 'LT' : 'SK',
        HOME_ID: date === TEST_DATE ? 'LG' : 'SS',
        AWAY_NM: date === TEST_DATE ? '롯데' : 'SSG',
        HOME_NM: date === TEST_DATE ? 'LG' : '삼성',
        GAME_STATE_SC: date === TEST_DATE ? '3' : '1',
        T_SCORE_CN: date === TEST_DATE ? 3 : 0,
        B_SCORE_CN: date === TEST_DATE ? 5 : 0
      }]
    }))

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(mockGameList).toHaveBeenCalledWith(TEST_DATE)
    expect(mockGameList).toHaveBeenCalledWith(TEST_NEXT_DATE)
    expect(result.games.map((game) => game.gameId)).toEqual([TEST_GAME_ID, nextGameId])
    expect(result.games[1]).toMatchObject({
      date: TEST_NEXT_DATE,
      venue: '대구',
      broadcastChannels: ['KBSN']
    })
  })

  it('enriches requested-date live games with the previous at-bat result', async () => {
    mockGameList.mockResolvedValue({
      game: [{
        G_ID: '20260627HTOB0',
        G_DT: TEST_DATE,
        G_TM: '17:00',
        S_NM: '잠실',
        AWAY_ID: 'HT',
        HOME_ID: 'OB',
        AWAY_NM: 'KIA',
        HOME_NM: '두산',
        GAME_STATE_SC: '2',
        GAME_INN_NO: 3,
        GAME_TB_SC: 'B',
        T_SCORE_CN: 0,
        B_SCORE_CN: 0,
        BALL_CN: 2,
        STRIKE_CN: 2,
        OUT_CN: 0,
        T_P_NM: '시라카와',
        B_P_NM: '박찬호'
      }]
    })
    mockLiveTextView.mockResolvedValue(`
      <span class="normaiflTxt"> 9번타자 박찬호<br /></span>
      <span class="normaiflTxt"> 박찬호 : 3루수 땅볼 아웃 (3루수-&gt;1루수 송구아웃)<br /></span>
    `)

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(mockLiveTextView).toHaveBeenCalledWith({
      gameId: '20260627HTOB0',
      gyear: TEST_DATE.slice(0, 4)
    })
    const game = result.games.find((candidate) => candidate.gameId === '20260627HTOB0')
    expect(game?.recentPlay).toBe('박찬호 : 3루수 땅볼 아웃 (3루수->1루수 송구아웃)')
    expect(game?.current).toEqual({
      batter: '박찬호',
      pitcher: '시라카와'
    })
  })

  it('keeps games when schedule rows do not match a game id', async () => {
    mockScheduleList.mockResolvedValue({ rows: [] })

    const result = await getTodayGames(TEST_INPUT_DATE)

    expect(result.games).toHaveLength(1)
    expect(result.games[0].gameId).toBe(TEST_GAME_ID)
    expect(result.games[0].venue).toBeNull()
    expect(result.games[0].broadcastChannels).toEqual([])
  })

  it('returns null game detail when the requested game is missing', async () => {
    const result = await getGameById('missing', TEST_INPUT_DATE)

    expect(result).toEqual({
      date: TEST_DATE,
      game: null
    })
  })

  it('includes raw and normalized payloads for debug source output', async () => {
    const result = await getTodayGamesRaw(TEST_INPUT_DATE)

    expect(result.requestedDate).toBe(TEST_DATE)
    expect(result.gameList.game).toHaveLength(1)
    expect(result.scheduleGames).toHaveLength(1)
    expect(result.normalizedGames[0].venue).toBe('잠실')
  })
})
