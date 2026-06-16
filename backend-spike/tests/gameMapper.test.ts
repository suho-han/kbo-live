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
  T_P_NM: '노시환',
  B_P_NM: '임찬규'
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

  it('synthesizes a live context fallback when source text is missing', () => {
    const game = mapGame(baseRawGame)

    expect(game.recentPlay).toBe('7회말 노시환 타석, 투수 임찬규, 카운트 2-1, 1아웃, 1,2루')
  })

  it('keeps recentPlay empty for non-live games without source text', () => {
    const game = mapGame({
      ...baseRawGame,
      GAME_STATE_SC: '3'
    })

    expect(game.recentPlay).toBeNull()
  })
})
