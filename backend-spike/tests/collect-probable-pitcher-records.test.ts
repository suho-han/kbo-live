import { describe, expect, it, vi } from 'vitest'

import { collectGame } from '../scripts/collect-probable-pitcher-records.js'
import type { RawKboGame } from '../src/dto/kboGameList.dto.js'

const scheduledGame = {
  G_ID: '20260708LGSS0',
  G_DT: '20260708',
  G_TM: '18:30',
  AWAY_ID: 'LG',
  HOME_ID: 'SS',
  AWAY_NM: 'LG',
  HOME_NM: '삼성',
  GAME_STATE_SC: '1',
  START_PIT_CK: '1'
} satisfies RawKboGame

describe('collect probable pitcher records starter policy', () => {
  it('reports not-due scheduled games without calling pitcher record analysis', async () => {
    const fetchPitcherRecordAnalysis = vi.fn()

    const result = await collectGame(scheduledGame, {
      now: new Date('2026-07-01T00:00:00+09:00'),
      fetchPitcherRecordAnalysis
    })

    expect(result).toEqual({
      gameId: '20260708LGSS0',
      reason: 'starter not due'
    })
    expect(fetchPitcherRecordAnalysis).not.toHaveBeenCalled()
  })

  it('reports missing starters for scheduled games inside the KST due window', async () => {
    const fetchPitcherRecordAnalysis = vi.fn()

    const result = await collectGame({
      ...scheduledGame,
      G_ID: '20260702LGSS0',
      G_DT: '20260702'
    }, {
      now: new Date('2026-07-01T00:00:00+09:00'),
      fetchPitcherRecordAnalysis
    })

    expect(result).toEqual({
      gameId: '20260702LGSS0',
      reason: 'missing starter id or name'
    })
    expect(fetchPitcherRecordAnalysis).not.toHaveBeenCalled()
  })
})
