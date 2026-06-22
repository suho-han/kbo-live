import { RawKboGame } from '../dto/kboGameList.dto.js'

interface MapStatusOptions {
  now?: Date
  scheduledStartTime?: string | null
}

export function mapStatus(
  raw: RawKboGame,
  options: MapStatusOptions = {}
): 'scheduled' | 'live' | 'final' | 'delayed' | 'cancelled' | 'unknown' {
  const state = String(raw.GAME_STATE_SC ?? '').trim()
  const cancelCode = typeof raw.CANCEL_SC_ID === 'string' ? raw.CANCEL_SC_ID.trim() : raw.CANCEL_SC_ID == null ? '' : String(raw.CANCEL_SC_ID).trim()
  const cancelName = typeof raw.CANCEL_SC_NM === 'string' ? raw.CANCEL_SC_NM.trim() : raw.CANCEL_SC_NM == null ? '' : String(raw.CANCEL_SC_NM).trim()
  const inning = raw.GAME_INN_NO
  const hasInning = inning !== null && inning !== undefined && inning !== '' && Number(inning) > 0
  const hasScore = Number(raw.T_SCORE_CN ?? 0) > 0 || Number(raw.B_SCORE_CN ?? 0) > 0
  const hasCount = hasMeaningfulValue(raw.BALL_CN)
    || hasMeaningfulValue(raw.STRIKE_CN)
    || hasMeaningfulValue(raw.OUT_CN)
  const hasTopBottom = raw.GAME_TB_SC === 'T' || raw.GAME_TB_SC === 'B'
  const hasLiveSignal = hasInning || hasScore || hasCount || hasTopBottom

  if ((cancelCode && cancelCode !== '0') || cancelName.includes('취소')) {
    return 'cancelled'
  }

  if (state === '1' && isBeforeScheduledStart(raw, options.now ?? new Date(), options.scheduledStartTime)) {
    return 'scheduled'
  }

  if (state === '1' && hasLiveSignal === false) {
    return 'scheduled'
  }

  if (state === '1' || state === '2') {
    return 'live'
  }

  if (state === '3' || state === '4') {
    return 'final'
  }

  if (state === '5') {
    return 'cancelled'
  }

  if (state === '6' || state === '7') {
    return 'delayed'
  }

  return 'unknown'
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

function isBeforeScheduledStart(raw: RawKboGame, now: Date, scheduledStartTime?: string | null): boolean {
  const start = scheduledStart(scheduledStartTime) ?? rawScheduledStart(raw)
  return start !== null && now.getTime() < start.getTime()
}

function rawScheduledStart(raw: RawKboGame): Date | null {
  const date = String(raw.G_DT ?? '').trim()
  const time = String(raw.G_TM ?? '').trim()
  return scheduledStart(date && time ? `${date}T${time}:00+09:00` : null)
}

function scheduledStart(value: string | null | undefined): Date | null {
  const trimmed = value?.trim()
  if (!trimmed) {
    return null
  }

  const compactMatch = /^(\d{4})(\d{2})(\d{2})T(\d{2}:\d{2}:\d{2})([+-]\d{2}:\d{2})$/.exec(trimmed)
  if (compactMatch) {
    const [, year, month, day, time, offset] = compactMatch
    const timestamp = Date.parse(`${year}-${month}-${day}T${time}${offset}`)
    return Number.isNaN(timestamp) ? null : new Date(timestamp)
  }

  const timestamp = Date.parse(trimmed)
  return Number.isNaN(timestamp) ? null : new Date(timestamp)
}
