import { describe, expect, it } from 'vitest'

import { mapGame } from '../src/mappers/gameMapper.js'
import type { RawKboGame } from '../src/dto/kboGameList.dto.js'

const baseRawGame: RawKboGame = {
  G_ID: '20260616HHLG0',
  G_DT: '20260616',
  G_TM: '18:30',
  S_NM: '잠실',
  AWAY_ID: 'HH',
  HOME_ID: 'LG',
  AWAY_NM: '한화',
  HOME_NM: 'LG',
  GAME_STATE_SC: '1',
  GAME_INN_NO: 7,
  GAME_TB_SC: 'B',
  T_SCORE_CN: 12,
  B_SCORE_CN: 9,
  STRIKE_CN: 1,
  BALL_CN: 2,
  OUT_CN: 1,
  B1_BAT_ORDER_NO: 4,
  B2_BAT_ORDER_NO: 5,
  B3_BAT_ORDER_NO: null,
  T_P_NM: '문동주',
  B_P_NM: '오지환'
}

describe('mapGame recentPlay', () => {
  it('uses explicit recent play source text when KBO provides it', () => {
    const game = mapGame({
      ...baseRawGame,
      RECENT_PLAY_TEXT: '7회말 노시환 좌전 안타'
    })

    expect(game.recentPlay).toBe('7회말 노시환 좌전 안타')
  })

  it('falls back through known KBO text candidates in a stable order', () => {
    const game = mapGame({
      ...baseRawGame,
      RECENT_PLAY_TEXT: '   ',
      RECENT_PLAY: null,
      LAST_PLAY_TEXT: '마지막 플레이 텍스트',
      LAST_PLAY: '마지막 플레이',
      LIVE_TEXT: '라이브 텍스트',
      GAME_TEXT: '게임 텍스트'
    })

    expect(game.recentPlay).toBe('마지막 플레이 텍스트')
  })

  it('keeps recentPlay empty for live games without an official result source', () => {
    const game = mapGame(baseRawGame)

    expect(game.current).toEqual({
      batter: '오지환',
      pitcher: '문동주'
    })
    expect(game.recentPlay).toBeNull()
  })

  it('maps top half current matchup as away batter against home pitcher', () => {
    const game = mapGame({
      ...baseRawGame,
      GAME_INN_NO: 1,
      GAME_TB_SC: 'T',
      T_P_NM: '홍창기',
      B_P_NM: '양현종'
    })

    expect(game.current).toEqual({
      batter: '홍창기',
      pitcher: '양현종'
    })
    expect(game.recentPlay).toBeNull()
  })

  it('maps bottom half current matchup as home batter against away pitcher', () => {
    const game = mapGame({
      ...baseRawGame,
      GAME_INN_NO: 1,
      GAME_TB_SC: 'B',
      T_P_NM: '톨허스트',
      B_P_NM: '김호령'
    })

    expect(game.current).toEqual({
      batter: '김호령',
      pitcher: '톨허스트'
    })
    expect(game.recentPlay).toBeNull()
  })

  it('keeps recentPlay empty for non-live games without source text', () => {
    const game = mapGame({
      ...baseRawGame,
      GAME_STATE_SC: '3'
    })

    expect(game.recentPlay).toBeNull()
  })

  it('keeps a status code 1 game scheduled when live fields are blank', () => {
    const game = mapGame({
      ...baseRawGame,
      GAME_INN_NO: '',
      GAME_TB_SC: '',
      T_SCORE_CN: '',
      B_SCORE_CN: '',
      BALL_CN: '',
      STRIKE_CN: '',
      OUT_CN: '',
      T_P_NM: '',
      B_P_NM: ''
    })

    expect(game.status).toBe('scheduled')
    expect(game.count).toBeNull()
    expect(game.recentPlay).toBeNull()
  })

  it('ignores KBO pregame live-looking fields before scheduled start', () => {
    const game = mapGame({
      ...baseRawGame,
      G_ID: '20260618LGHT0',
      G_DT: '20260618',
      G_TM: '18:30',
      GAME_INN_NO: null,
      GAME_TB_SC: null,
      T_SCORE_CN: '0',
      B_SCORE_CN: '0',
      BALL_CN: 0,
      STRIKE_CN: 0,
      OUT_CN: 0,
      T_P_NM: '양현종',
      B_P_NM: '양현종'
    }, undefined, { now: new Date('2026-06-18T08:34:55Z') })

    expect(game.status).toBe('scheduled')
    expect(game.inning).toBeNull()
    expect(game.count).toBeNull()
    expect(game.bases).toBeNull()
    expect(game.current).toBeNull()
    expect(game.recentPlay).toBeNull()
  })

  it('uses schedule metadata start time to suppress pregame live-looking fields', () => {
    const game = mapGame({
      ...baseRawGame,
      G_ID: '20260618LGHT0',
      G_DT: '20260618',
      G_TM: null,
      GAME_INN_NO: 1,
      GAME_TB_SC: 'T',
      T_SCORE_CN: '0',
      B_SCORE_CN: '0',
      BALL_CN: 0,
      STRIKE_CN: 0,
      OUT_CN: 0,
      T_P_NM: '홍창기',
      B_P_NM: '양현종'
    }, {
      gameId: '20260618LGHT0',
      date: '20260618',
      awayTeam: {
        id: 'LG',
        name: 'LG'
      },
      homeTeam: {
        id: 'HT',
        name: 'KIA'
      },
      startTime: '20260618T18:30:00+09:00',
      venue: '광주',
      broadcastChannels: ['S-T'],
      note: null,
      statusHint: null,
      links: {
        gameCenter: null,
        preview: null,
        review: null,
        highlight: null
      }
    }, { now: new Date('2026-06-18T08:56:50Z') })

    expect(game.status).toBe('scheduled')
    expect(game.startTime).toBe('20260618T18:30:00+09:00')
    expect(game.inning).toBeNull()
    expect(game.count).toBeNull()
    expect(game.bases).toBeNull()
    expect(game.current).toBeNull()
    expect(game.recentPlay).toBeNull()
  })

  it('maps pitcher decision names when KBO provides them', () => {
    const game = mapGame({
      ...baseRawGame,
      W_PIT_P_NM: '임찬규',
      L_PIT_P_NM: '문동주',
      SV_PIT_P_NM: '유영찬'
    })

    expect(game.pitcherDecisions).toEqual({
      win: '임찬규',
      loss: '문동주',
      save: '유영찬'
    })
  })
})
