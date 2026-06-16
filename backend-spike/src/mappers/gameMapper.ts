import { mapBases } from './baseMapper.js'
import { mapStatus } from './statusMapper.js'
import type { RawKboGame } from '../dto/kboGameList.dto.js'
import type { NormalizedGame } from '../models/normalizedGame.js'
import type { ScheduleGameInfo } from './scheduleMapper.js'

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

function mapInningText(number: number, half: 'top' | 'bottom' | null): string | null {
  if (!half || number <= 0) return null
  return `${number}회${half === 'top' ? '초' : '말'}`
}

function mapBaseText(bases: NormalizedGame['bases']): string | null {
  if (!bases) return null

  const occupied = [
    bases.first ? '1' : null,
    bases.second ? '2' : null,
    bases.third ? '3' : null
  ].filter(Boolean)

  return occupied.length > 0 ? `${occupied.join(',')}루` : '주자 없음'
}

function mapRecentPlay(raw: RawKboGame, game: {
  status: NormalizedGame['status']
  inning: NormalizedGame['inning']
  count: NormalizedGame['count']
  bases: NormalizedGame['bases']
  current: NonNullable<NormalizedGame['current']>
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
  if (game.status !== 'live') return null

  const inning = mapInningText(game.inning?.number ?? 0, game.inning?.half ?? null)
  const baseText = mapBaseText(game.bases)
  const countText = game.count ? `카운트 ${game.count.balls}-${game.count.strikes}, ${game.count.outs}아웃` : null

  const parts = [
    inning && game.current.batter ? `${inning} ${game.current.batter} 타석` : inning,
    game.current.pitcher ? `투수 ${game.current.pitcher}` : null,
    countText,
    baseText
  ].filter(Boolean)

  return parts.length > 0 ? parts.join(', ') : null
}

export function mapGame(raw: RawKboGame, scheduleInfo?: ScheduleGameInfo): NormalizedGame {
  const half = mapHalf(raw.GAME_TB_SC)
  const inningNumber = toNumber(raw.GAME_INN_NO)
  const status = mapStatus(raw)
  const inning: NormalizedGame['inning'] = half && inningNumber > 0 ? { number: inningNumber, half } : null
  const count: NormalizedGame['count'] = raw.BALL_CN != null || raw.STRIKE_CN != null || raw.OUT_CN != null
    ? {
        balls: toNumber(raw.BALL_CN),
        strikes: toNumber(raw.STRIKE_CN),
        outs: toNumber(raw.OUT_CN)
      }
    : null
  const bases = mapBases(raw)
  const current: NonNullable<NormalizedGame['current']> = {
    batter: trimToNull(raw.T_P_NM),
    pitcher: trimToNull(raw.B_P_NM)
  }

  return {
    gameId: raw.G_ID,
    date: String(raw.G_DT ?? ''),
    venue: trimToNull(raw.S_NM) ?? scheduleInfo?.venue ?? null,
    startTime: raw.G_DT && raw.G_TM ? `${raw.G_DT}T${raw.G_TM}:00+09:00` : scheduleInfo?.startTime ?? null,
    broadcastChannels: scheduleInfo?.broadcastChannels ?? [],
    homepageLinks: scheduleInfo?.links ?? {
      gameCenter: null,
      preview: null,
      review: null,
      highlight: null
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
    current,
    probablePitchers: {
      away: trimToNull(raw.T_PIT_P_NM),
      home: trimToNull(raw.B_PIT_P_NM)
    },
    recentPlay: mapRecentPlay(raw, { status, inning, count, bases, current }),
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
  return {
    gameId: scheduleInfo.gameId,
    date: scheduleInfo.date,
    venue: scheduleInfo.venue,
    startTime: scheduleInfo.startTime,
    broadcastChannels: scheduleInfo.broadcastChannels,
    homepageLinks: scheduleInfo.links,
    status: 'scheduled',
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
