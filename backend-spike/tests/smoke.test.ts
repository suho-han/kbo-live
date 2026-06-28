import { describe, expect, it } from 'vitest'

import { mapBases } from '../src/mappers/baseMapper.js'
import { mapGame, mapScheduledGame } from '../src/mappers/gameMapper.js'
import { mapScheduleGames } from '../src/mappers/scheduleMapper.js'
import { mapStatus } from '../src/mappers/statusMapper.js'
import { summarizeGameChanges } from '../src/utils/gameSnapshot.js'
import { toKboDate } from '../src/utils/date.js'
import type { NormalizedGame } from '../src/models/normalizedGame.js'
import { TEST_KOREA_ROLLOVER_INSTANT, TEST_NEXT_DATE } from './testConfig.js'

describe('backend-spike smoke', () => {
  it('maps bases from occupied runners', () => {
    expect(mapBases({ B1_BAT_ORDER_NO: 1, B2_BAT_ORDER_NO: null, B3_BAT_ORDER_NO: 9 } as never)).toEqual({
      first: true,
      second: false,
      third: true
    })
  })

  it('maps scheduled status when inning is absent', () => {
    expect(mapStatus({ GAME_STATE_SC: '1', GAME_INN_NO: null } as never)).toBe('scheduled')
  })

  it('keeps status code 1 scheduled when only blank live fields are present', () => {
    expect(mapStatus({
      GAME_STATE_SC: '1',
      GAME_INN_NO: '',
      GAME_TB_SC: '',
      T_SCORE_CN: '',
      B_SCORE_CN: '',
      BALL_CN: '',
      STRIKE_CN: '   ',
      OUT_CN: ''
    } as never)).toBe('scheduled')
  })

  it('keeps status code 1 scheduled before first pitch even when KBO preloads live-looking fields', () => {
    expect(mapStatus({
      G_DT: '20260618',
      G_TM: '18:30',
      GAME_STATE_SC: '1',
      GAME_INN_NO: 1,
      GAME_TB_SC: 'T',
      T_SCORE_CN: '0',
      B_SCORE_CN: '0',
      BALL_CN: 0,
      STRIKE_CN: 0,
      OUT_CN: 0
    } as never, { now: new Date('2026-06-18T08:34:55Z') })).toBe('scheduled')
  })

  it('maps status code 1 as live when live-only fields are present', () => {
    expect(mapStatus({
      G_DT: '20260618',
      G_TM: '18:30',
      GAME_STATE_SC: '1',
      GAME_INN_NO: null,
      GAME_TB_SC: 'T',
      T_SCORE_CN: 1,
      B_SCORE_CN: 0,
      BALL_CN: 0,
      STRIKE_CN: 0,
      OUT_CN: 0
    } as never, { now: new Date('2026-06-18T09:30:00Z') })).toBe('live')
  })

  it('maps cancelled and delayed status codes explicitly', () => {
    expect(mapStatus({ GAME_STATE_SC: '5' } as never)).toBe('cancelled')
    expect(mapStatus({ GAME_STATE_SC: '6' } as never)).toBe('delayed')
    expect(mapStatus({ GAME_STATE_SC: '7' } as never)).toBe('delayed')
  })

  it('lets explicit cancellation metadata override final-looking state codes', () => {
    expect(mapStatus({
      GAME_STATE_SC: '4',
      GAME_INN_NO: 0,
      T_SCORE_CN: '0',
      B_SCORE_CN: '0',
      CANCEL_SC_ID: '1',
      CANCEL_SC_NM: '우천취소'
    } as never)).toBe('cancelled')
    expect(mapStatus({ GAME_STATE_SC: '4', CANCEL_SC_ID: 0, CANCEL_SC_NM: '' } as never)).toBe('final')
    expect(mapStatus({ GAME_STATE_SC: '3', CANCEL_SC_ID: 0, CANCEL_SC_NM: '정상경기' } as never)).toBe('final')
  })

  it('summarizes meaningful live changes between polling ticks', () => {
    const previous = [buildGame({ score: { away: 1, home: 0 }, inning: { number: 3, half: 'top' }, count: { balls: 1, strikes: 1, outs: 1 } })]
    const current = [buildGame({ score: { away: 2, home: 0 }, inning: { number: 3, half: 'top' }, count: { balls: 0, strikes: 0, outs: 2 } })]

    expect(summarizeGameChanges(previous, current)).toEqual([
      {
        gameId: '20260610SKLG0',
        matchup: 'SSG @ LG',
        changes: [
          'score SSG 1:0 LG -> SSG 2:0 LG',
          'count {"balls":1,"strikes":1,"outs":1} -> {"balls":0,"strikes":0,"outs":2}'
        ]
      }
    ])
  })

  it('normalizes requested dates into KBO date format', () => {
    expect(toKboDate('2026-06-01')).toBe('20260601')
    expect(toKboDate('20260601')).toBe('20260601')
  })

  it('uses the Korea date for default KBO date normalization', () => {
    expect(toKboDate(undefined, TEST_KOREA_ROLLOVER_INSTANT)).toBe(TEST_NEXT_DATE)
  })

  it('extracts game center metadata from KBO schedule rows', () => {
    const games = mapScheduleGames({
      rows: [{
        row: [
          { Text: '06.10(수)', Class: 'day' },
          { Text: '<b>18:30</b>', Class: 'time' },
          { Text: '<span>SSG</span><em><span>vs</span></em><span>LG</span>', Class: 'play' },
          { Text: "<a href='/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT'>프리뷰</a>", Class: 'relay' },
          { Text: '', Class: null },
          { Text: 'SPO-2T', Class: null },
          { Text: '', Class: null },
          { Text: '잠실', Class: null },
          { Text: '-', Class: null }
        ]
      }]
    })

    expect(games).toEqual([{
      gameId: '20260610SKLG0',
      date: '20260610',
      awayTeam: {
        id: 'SK',
        name: 'SSG'
      },
      homeTeam: {
        id: 'LG',
        name: 'LG'
      },
      startTime: '20260610T18:30:00+09:00',
      venue: '잠실',
      broadcastChannels: ['SPO-2T'],
      note: null,
      statusHint: null,
      links: {
        gameCenter: 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT',
        preview: 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT',
        review: null,
        highlight: null
      }
    }])
  })

  it('recovers linkless cancelled schedule rows from date and team names', () => {
    const games = mapScheduleGames({
      rows: [
        {
          row: [
            { Text: '06.14(일)', Class: 'day' },
            { Text: '<b>14:00</b>', Class: 'time' },
            { Text: '<span>한화</span><em><span class="lose">2</span><span>vs</span><span class="win">3</span></em><span>키움</span>', Class: 'play' },
            { Text: "<a href='/Schedule/GameCenter/Main.aspx?gameDate=20260614&gameId=20260614HHWO0&section=REVIEW'>리뷰</a>", Class: 'relay' },
            { Text: '', Class: null },
            { Text: 'S-T', Class: null },
            { Text: '', Class: null },
            { Text: '고척', Class: null },
            { Text: '-', Class: null }
          ]
        },
        {
          row: [
            { Text: '<b>17:00</b>', Class: 'time' },
            { Text: '<span>NC</span><em><span>vs</span></em><span>KT</span>', Class: 'play' },
            { Text: '', Class: 'relay' },
            { Text: '', Class: null },
            { Text: 'SPO-T<br />SS-T', Class: null },
            { Text: '', Class: null },
            { Text: '수원', Class: null },
            { Text: '우천취소', Class: null }
          ]
        }
      ]
    })

    expect(games.at(-1)).toMatchObject({
      gameId: '20260614NCKT0',
      date: '20260614',
      awayTeam: {
        id: 'NC',
        name: 'NC'
      },
      homeTeam: {
        id: 'KT',
        name: 'KT'
      },
      startTime: '20260614T17:00:00+09:00',
      venue: '수원',
      broadcastChannels: ['SPO-T', 'SS-T'],
      note: '우천취소',
      statusHint: 'cancelled',
      links: {
        gameCenter: null,
        preview: null,
        review: null,
        highlight: null
      }
    })
    expect(mapScheduledGame(games.at(-1)!).status).toBe('cancelled')
  })

  it('enriches normalized games with schedule metadata', () => {
    const game = mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: null,
      S_NM: null,
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '1'
    }, {
      gameId: '20260610SKLG0',
      date: '20260610',
      awayTeam: {
        id: 'SK',
        name: 'SSG'
      },
      homeTeam: {
        id: 'LG',
        name: 'LG'
      },
      startTime: '20260610T18:30:00+09:00',
      venue: '잠실',
      broadcastChannels: ['SPO-2T'],
      note: null,
      statusHint: null,
      links: {
        gameCenter: 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT',
        preview: 'https://www.koreabaseball.com/Schedule/GameCenter/Main.aspx?gameDate=20260610&gameId=20260610SKLG0&section=START_PIT',
        review: null,
        highlight: null
      }
    })

    expect(game.startTime).toBe('20260610T18:30:00+09:00')
    expect(game.venue).toBe('잠실')
    expect(game.broadcastChannels).toEqual(['SPO-2T'])
    expect(game.homepageLinks.preview).toContain('section=START_PIT')
  })

  it('maps source recent play text when KBO provides it', () => {
    const game = mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: '18:30',
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '2',
      RECENT_PLAY_TEXT: '문보경 좌전 적시타'
    })

    expect(game.recentPlay).toBe('문보경 좌전 적시타')
  })

  it('does not build a live situation recent play fallback from game list fields', () => {
    const game = mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: '18:30',
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '2',
      GAME_INN_NO: 5,
      GAME_TB_SC: 'T',
      BALL_CN: 1,
      STRIKE_CN: 2,
      OUT_CN: 1,
      B1_BAT_ORDER_NO: 4,
      B2_BAT_ORDER_NO: 0,
      B3_BAT_ORDER_NO: 7,
      T_P_NM: ' 최정 ',
      B_P_NM: ' 임찬규 '
    })

    expect(game.current).toEqual({
      batter: '최정',
      pitcher: '임찬규'
    })
    expect(game.recentPlay).toBeNull()
  })

  it('does not build a fallback recent play for completed games', () => {
    const game = mapGame({
      G_ID: '20260610SKLG0',
      G_DT: '20260610',
      G_TM: '18:30',
      AWAY_ID: 'SK',
      HOME_ID: 'LG',
      AWAY_NM: 'SSG',
      HOME_NM: 'LG',
      GAME_STATE_SC: '3',
      GAME_INN_NO: 9,
      GAME_TB_SC: 'B',
      T_P_NM: '오지환',
      B_P_NM: '김광현'
    })

    expect(game.recentPlay).toBeNull()
  })
})

function buildGame(overrides: Partial<NormalizedGame> = {}): NormalizedGame {
  return {
    gameId: '20260610SKLG0',
    date: '20260610',
    venue: '잠실',
    startTime: '2026-06-10T18:30:00+09:00',
    broadcastChannels: [],
    homepageLinks: {
      gameCenter: null,
      preview: null,
      review: null,
      highlight: null
    },
    pitcherDecisions: {
      win: null,
      loss: null,
      save: null
    },
    status: 'live',
    awayTeam: { id: 'SK', name: 'SSG' },
    homeTeam: { id: 'LG', name: 'LG' },
    score: { away: 0, home: 0 },
    inning: { number: 1, half: 'top' },
    count: { balls: 0, strikes: 0, outs: 0 },
    bases: { first: false, second: false, third: false },
    current: { batter: null, pitcher: null },
    probablePitchers: { away: null, home: null },
    recentPlay: null,
    teamRecords: null,
    boxScore: null,
    lineupPreview: null,
    analysis: null,
    sourceMeta: {
      rawStatusCode: '1',
      rawTopBottomCode: 'T',
      fetchedAt: '2026-06-10T09:00:00.000Z'
    },
    ...overrides
  }
}
