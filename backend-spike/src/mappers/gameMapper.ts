import { mapBases } from './baseMapper.js'
import { mapStatus } from './statusMapper.js'
import type { RawKboGame } from '../dto/kboGameList.dto.js'
import type { NormalizedGame } from '../models/normalizedGame.js'
import type { ScheduleGameInfo } from './scheduleMapper.js'

interface MapGameOptions {
  now?: Date
}

function toNumber(value: string | number | null | undefined): number {
  const num = Number(value ?? 0)
  return Number.isFinite(num) ? num : 0
}

function mapHalf(value: string | null | undefined): 'top' | 'bottom' | null {
  if (value === 'T') return 'top'
  if (value === 'B') return 'bottom'
  return null
}

function trimToNull(value: string | null | undefined): string | null {
  const trimmed = value?.trim()
  return trimmed ? trimmed : null
}

function hasMeaningfulValue(value: string | number | null | undefined): boolean {
  if (value === null || value === undefined) {
    return false
  }

  if (typeof value === 'string') {
    return value.trim().length > 0
  }

  return Number.isFinite(value)
}

function mapCurrentMatchup(raw: RawKboGame, half: 'top' | 'bottom' | null): NonNullable<NormalizedGame['current']> {
  if (half === 'bottom') {
    return {
      batter: trimToNull(raw.B_P_NM),
      pitcher: trimToNull(raw.T_P_NM)
    }
  }

  return {
    batter: trimToNull(raw.T_P_NM),
    pitcher: trimToNull(raw.B_P_NM)
  }
}

function mapRecentPlay(raw: RawKboGame, game: {
  status: NormalizedGame['status']
}): string | null {
  const sourceText = [
    raw.RECENT_PLAY_TEXT,
    raw.RECENT_PLAY,
    raw.LAST_PLAY_TEXT,
    raw.LAST_PLAY,
    raw.LIVE_TEXT,
    raw.GAME_TEXT
  ].map(trimToNull).find(Boolean)

  if (sourceText) return sourceText
  return null
}

export function mapGame(raw: RawKboGame, scheduleInfo?: ScheduleGameInfo, options: MapGameOptions = {}): NormalizedGame {
  const half = mapHalf(raw.GAME_TB_SC)
  const inningNumber = toNumber(raw.GAME_INN_NO)
  const startTime = raw.G_DT && raw.G_TM ? `${raw.G_DT}T${raw.G_TM}:00+09:00` : scheduleInfo?.startTime ?? null
  const status = mapStatus(raw, {
    now: options.now,
    scheduledStartTime: startTime
  })
  const inning: NormalizedGame['inning'] = status === 'live' && half && inningNumber > 0 ? { number: inningNumber, half } : null
  const hasCount = hasMeaningfulValue(raw.BALL_CN) || hasMeaningfulValue(raw.STRIKE_CN) || hasMeaningfulValue(raw.OUT_CN)
  const count: NormalizedGame['count'] = status === 'live' && hasCount
    ? {
        balls: toNumber(raw.BALL_CN),
        strikes: toNumber(raw.STRIKE_CN),
        outs: toNumber(raw.OUT_CN)
      }
    : null
  const bases = status === 'live' ? mapBases(raw) : null
  const current = mapCurrentMatchup(raw, half)

  return {
    gameId: raw.G_ID,
    date: String(raw.G_DT ?? ''),
    venue: trimToNull(raw.S_NM) ?? scheduleInfo?.venue ?? null,
    startTime,
    broadcastChannels: scheduleInfo?.broadcastChannels ?? [],
    homepageLinks: scheduleInfo?.links ?? {
      gameCenter: null,
      preview: null,
      review: null,
      highlight: null
    },
    pitcherDecisions: {
      win: trimToNull(raw.W_PIT_P_NM),
      loss: trimToNull(raw.L_PIT_P_NM),
      save: trimToNull(raw.SV_PIT_P_NM)
    },
    status,
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
    inning,
    count,
    bases,
    current: status === 'live' ? current : null,
    probablePitchers: {
      away: trimToNull(raw.T_PIT_P_NM),
      home: trimToNull(raw.B_PIT_P_NM)
    },
    recentPlay: mapRecentPlay(raw, { status }),
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

export function mapScheduledGame(scheduleInfo: ScheduleGameInfo): NormalizedGame {
  const status = scheduleInfo.statusHint ?? 'scheduled'

  return {
    gameId: scheduleInfo.gameId,
    date: scheduleInfo.date,
    venue: scheduleInfo.venue,
    startTime: scheduleInfo.startTime,
    broadcastChannels: scheduleInfo.broadcastChannels,
    homepageLinks: scheduleInfo.links,
    pitcherDecisions: {
      win: null,
      loss: null,
      save: null
    },
    status,
    awayTeam: scheduleInfo.awayTeam,
    homeTeam: scheduleInfo.homeTeam,
    score: {
      away: 0,
      home: 0
    },
    inning: null,
    count: null,
    bases: null,
    current: null,
    probablePitchers: {
      away: null,
      home: null
    },
    recentPlay: null,
    teamRecords: null,
    boxScore: {
      away: {
        runs: 0,
        hits: null,
        errors: null,
        walks: null
      },
      home: {
        runs: 0,
        hits: null,
        errors: null,
        walks: null
      },
      linescore: []
    },
    lineupPreview: null,
    analysis: null,
    sourceMeta: {
      rawStatusCode: null,
      rawTopBottomCode: null,
      fetchedAt: new Date().toISOString()
    }
  }
}
