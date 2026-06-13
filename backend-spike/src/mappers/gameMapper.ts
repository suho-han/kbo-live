import { mapBases } from './baseMapper.js'
import { mapStatus } from './statusMapper.js'
import type { RawKboGame } from '../dto/kboGameList.dto.js'
import type { NormalizedGame } from '../models/normalizedGame.js'

function toNumber(value: string | number | null | undefined): number {
  const num = Number(value ?? 0)
  return Number.isFinite(num) ? num : 0
}

function mapHalf(value: string | null | undefined): 'top' | 'bottom' | null {
  if (value === 'T') return 'top'
  if (value === 'B') return 'bottom'
  return null
}

export function mapGame(raw: RawKboGame): NormalizedGame {
  const half = mapHalf(raw.GAME_TB_SC)
  const inningNumber = toNumber(raw.GAME_INN_NO)

  return {
    gameId: raw.G_ID,
    date: String(raw.G_DT ?? ''),
    venue: raw.S_NM ?? null,
    startTime: raw.G_DT && raw.G_TM ? `${raw.G_DT}T${raw.G_TM}:00+09:00` : null,
    status: mapStatus(raw),
    awayTeam: {
      id: raw.AWAY_ID ?? '',
      name: raw.AWAY_NM ?? ''
    },
    homeTeam: {
      id: raw.HOME_ID ?? '',
      name: raw.HOME_NM ?? ''
    },
    score: {
      away: toNumber(raw.T_SCORE_CN),
      home: toNumber(raw.B_SCORE_CN)
    },
    inning: half && inningNumber > 0 ? { number: inningNumber, half } : null,
    count: raw.BALL_CN != null || raw.STRIKE_CN != null || raw.OUT_CN != null
      ? {
          balls: toNumber(raw.BALL_CN),
          strikes: toNumber(raw.STRIKE_CN),
          outs: toNumber(raw.OUT_CN)
        }
      : null,
    bases: mapBases(raw),
    current: {
      batter: raw.T_P_NM ?? null,
      pitcher: raw.B_P_NM ?? null
    },
    probablePitchers: {
      away: raw.T_PIT_P_NM?.trim() ?? null,
      home: raw.B_PIT_P_NM?.trim() ?? null
    },
    recentPlay: null,
    teamRecords: null,
    boxScore: {
      away: {
        runs: toNumber(raw.T_SCORE_CN),
        hits: null,
        errors: null,
        walks: null
      },
      home: {
        runs: toNumber(raw.B_SCORE_CN),
        hits: null,
        errors: null,
        walks: null
      },
      linescore: []
    },
    lineupPreview: null,
    analysis: null,
    sourceMeta: {
      rawStatusCode: raw.GAME_STATE_SC ?? null,
      rawTopBottomCode: raw.GAME_TB_SC ?? null,
      fetchedAt: new Date().toISOString()
    }
  }
}
