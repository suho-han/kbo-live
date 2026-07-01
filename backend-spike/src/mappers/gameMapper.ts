import { mapBases } from './baseMapper.js'
import { mapStatus } from './statusMapper.js'
import type { RawKboGame } from '../dto/kboGameList.dto.js'
import type { NormalizedGame, StarterStatus } from '../models/normalizedGame.js'
import type { ScheduleGameInfo } from './scheduleMapper.js'

interface MapGameOptions {
  now?: Date
}

interface MapScheduledGameOptions {
  now?: Date
}

const ONE_DAY_MS = 86_400_000

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

function kstDateKey(date: Date): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).formatToParts(date)
  const year = parts.find((part) => part.type === 'year')?.value ?? '0000'
  const month = parts.find((part) => part.type === 'month')?.value ?? '00'
  const day = parts.find((part) => part.type === 'day')?.value ?? '00'

  return `${year}${month}${day}`
}

function addDays(dateKey: string, days: number): string {
  const year = Number(dateKey.slice(0, 4))
  const month = Number(dateKey.slice(4, 6))
  const day = Number(dateKey.slice(6, 8))

  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
    return dateKey
  }

  const date = new Date(Date.UTC(year, month - 1, day) + (days * ONE_DAY_MS))
  return [
    String(date.getUTCFullYear()).padStart(4, '0'),
    String(date.getUTCMonth() + 1).padStart(2, '0'),
    String(date.getUTCDate()).padStart(2, '0')
  ].join('')
}

function starterStatusForGame(input: {
  status: NormalizedGame['status']
  date: string
  awayName: string | null
  homeName: string | null
  now?: Date
}): StarterStatus {
  if (input.awayName != null && input.homeName != null) {
    return 'ready'
  }

  if (input.status !== 'scheduled') {
    return 'ready'
  }

  const tomorrow = addDays(kstDateKey(input.now ?? new Date()), 1)
  return input.date > tomorrow ? 'notDue' : 'missing'
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
  const awayStarterName = trimToNull(raw.T_PIT_P_NM)
  const homeStarterName = trimToNull(raw.B_PIT_P_NM)

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
    starterStatus: starterStatusForGame({
      status,
      date: String(raw.G_DT ?? ''),
      awayName: awayStarterName,
      homeName: homeStarterName,
      now: options.now
    }),
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
      away: {
        name: awayStarterName,
        record: null
      },
      home: {
        name: homeStarterName,
        record: null
      }
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

export function mapScheduledGame(scheduleInfo: ScheduleGameInfo, options: MapScheduledGameOptions = {}): NormalizedGame {
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
    starterStatus: starterStatusForGame({
      status,
      date: scheduleInfo.date,
      awayName: null,
      homeName: null,
      now: options.now
    }),
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
      away: {
        name: null,
        record: null
      },
      home: {
        name: null,
        record: null
      }
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
