import { RawKboGame } from '../dto/kboGameList.dto.js'

export function mapStatus(raw: RawKboGame): 'scheduled' | 'live' | 'final' | 'delayed' | 'cancelled' | 'unknown' {
  const state = String(raw.GAME_STATE_SC ?? '').trim()
  const inning = raw.GAME_INN_NO
  const hasInning = inning !== null && inning !== undefined && inning !== '' && Number(inning) > 0
  const hasScore = Number(raw.T_SCORE_CN ?? 0) > 0 || Number(raw.B_SCORE_CN ?? 0) > 0
  const hasCount = raw.BALL_CN !== null && raw.BALL_CN !== undefined
    || raw.STRIKE_CN !== null && raw.STRIKE_CN !== undefined
    || raw.OUT_CN !== null && raw.OUT_CN !== undefined
  const hasTopBottom = raw.GAME_TB_SC === 'T' || raw.GAME_TB_SC === 'B'
  const hasLiveSignal = hasInning || hasScore || hasCount || hasTopBottom

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
