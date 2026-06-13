import { describe, expect, it } from 'vitest'

import { mapBases } from '../src/mappers/baseMapper.js'
import { mapStatus } from '../src/mappers/statusMapper.js'
import { summarizeGameChanges } from '../src/utils/gameSnapshot.js'
import { toKboDate } from '../src/utils/date.js'
import type { NormalizedGame } from '../src/models/normalizedGame.js'

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
})

function buildGame(overrides: Partial<NormalizedGame> = {}): NormalizedGame {
  return {
    gameId: '20260610SKLG0',
    date: '20260610',
    venue: '잠실',
    startTime: '2026-06-10T18:30:00+09:00',
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
