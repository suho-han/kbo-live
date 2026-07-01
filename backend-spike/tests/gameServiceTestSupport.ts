import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { vi } from 'vitest'

import { fetchKboGameDate, fetchKboGameList, fetchKboLiveTextView, fetchKboScheduleList, fetchKboTeamRankDailyPage } from '../src/clients/kboClient.js'
import { closeDatabase } from '../src/db/database.js'
import { upsertPitchingSeasonRecords } from '../src/repositories/playerRecordRepository.js'
import { clearGameServiceCacheForTests } from '../src/services/gameService.js'
import { TEST_DATE, TEST_GAME_ID, TEST_MONTH, TEST_NEXT_DATE, TEST_SEASON } from './testConfig.js'

export const mockGameDate = vi.mocked(fetchKboGameDate)
export const mockGameList = vi.mocked(fetchKboGameList)
export const mockLiveTextView = vi.mocked(fetchKboLiveTextView)
export const mockScheduleList = vi.mocked(fetchKboScheduleList)
export const mockTeamRankDailyPage = vi.mocked(fetchKboTeamRankDailyPage)

const teamRankHtml = `
<table summary="순위, 팀명,승,패,무,승률,승차,최근10경기,연속,홈,방문" class="tData">
  <tbody>
    <tr><td>1</td><td>LG</td><td>65</td><td>41</td><td>24</td><td>0</td><td>0.631</td><td>0</td><td>7승0무3패</td><td>2승</td><td>24-0-11</td><td>17-0-13</td></tr>
    <tr><td>10</td><td>롯데</td><td>64</td><td>24</td><td>39</td><td>1</td><td>0.381</td><td>16</td><td>2승0무8패</td><td>2패</td><td>9-0-22</td><td>15-1-17</td></tr>
  </tbody>
</table>`

export function resetGameServiceTestState(): void {
  vi.clearAllMocks()
  clearGameServiceCacheForTests()
  delete process.env.KBO_USE_TEST_LIVE_GAME
  delete process.env.KBO_CACHE_TTL_GAME_IDLE_SEC
  delete process.env.KBO_CACHE_TTL_GAME_LIVE_SEC
  delete process.env.KBO_CACHE_STALE_IF_ERROR_SEC
  delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
  delete process.env.BASEBALL_LIVE_KR_DB_PATH
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
}

export function cleanupGameServiceTestState(tempDirs: string[]): void {
  clearGameServiceCacheForTests()
  delete process.env.KBO_USE_TEST_LIVE_GAME
  delete process.env.KBO_CACHE_TTL_GAME_IDLE_SEC
  delete process.env.KBO_CACHE_TTL_GAME_LIVE_SEC
  delete process.env.KBO_CACHE_STALE_IF_ERROR_SEC
  delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
  delete process.env.BASEBALL_LIVE_KR_DB_PATH
  closeDatabase()
  for (const dir of tempDirs.splice(0)) {
    rmSync(dir, { recursive: true, force: true })
  }
}

export function seedPitcherRecord(
  tempDirs: string[],
  prefix: string,
  overrides: Partial<{
    playerId: string
    playerName: string
    teamId: string
    teamName: string
  }> = {}
): void {
  process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
  const dir = mkdtempSync(join(tmpdir(), prefix))
  tempDirs.push(dir)
  process.env.BASEBALL_LIVE_KR_DB_PATH = join(dir, 'test.sqlite')
  upsertPitchingSeasonRecords(TEST_DATE, [{
    playerId: overrides.playerId ?? '55633',
    playerName: overrides.playerName ?? '올러',
    teamId: overrides.teamId ?? 'LG',
    teamName: overrides.teamName ?? 'LG',
    rank: 1,
    games: 14,
    completeGames: 1,
    shutouts: 1,
    wins: 7,
    losses: 5,
    saves: 0,
    holds: 0,
    winningPercentage: 0.583,
    plateAppearances: 344,
    pitches: 1314,
    inningsPitchedOuts: 262,
    hitsAllowed: 56,
    doublesAllowed: 6,
    triplesAllowed: 2,
    homeRunsAllowed: 6,
    era: 2.58,
    walks: 27,
    strikeouts: 92,
    earnedRuns: 25,
    whip: 0.95
  }])
}

export function buildStarterScheduleList() {
  return {
    rows: [{
      row: [
        { Text: '06.13(토)', Class: 'day' },
        { Text: '<b>18:30</b>', Class: 'time' },
        { Text: '<span>SSG</span><em><span>vs</span></em><span>KIA</span>', Class: 'play' },
        { Text: `<a href='/Schedule/GameCenter/Main.aspx?gameDate=${TEST_DATE}&gameId=${TEST_GAME_ID}&section=START_PIT'>프리뷰</a>`, Class: 'relay' },
        { Text: '', Class: null },
        { Text: 'MS-T', Class: null },
        { Text: '', Class: null },
        { Text: '광주', Class: null },
        { Text: '-', Class: null }
      ]
    }]
  }
}

export function buildStarterGameList() {
  return {
    game: [{
      G_ID: TEST_GAME_ID,
      G_DT: TEST_DATE,
      G_TM: '18:30',
      S_NM: '광주',
      AWAY_ID: 'SK',
      HOME_ID: 'HT',
      AWAY_NM: 'SSG',
      HOME_NM: 'KIA',
      GAME_STATE_SC: '1',
      T_SCORE_CN: 0,
      B_SCORE_CN: 0,
      T_PIT_P_NM: '김건우',
      B_PIT_P_NM: '올러'
    }]
  }
}

export function buildMonthScheduleList() {
  const nextGameId = `${TEST_NEXT_DATE}SKSS0`
  return {
    nextGameId,
    scheduleList: {
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
    }
  }
}

export function buildMonthGameList(date: string, nextGameId: string) {
  return {
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
  }
}

export { TEST_DATE, TEST_GAME_ID, TEST_INPUT_DATE, TEST_MONTH, TEST_NEXT_DATE, TEST_SEASON, TEST_START_TIME } from './testConfig.js'
