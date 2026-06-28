import { buildKboHeaders } from '../config/kboHeaders.js'
import { rawKboGameDateResponseSchema } from '../dto/kboGameDate.dto.js'
import { rawKboGameListResponseSchema } from '../dto/kboGameList.dto.js'
import { rawKboScheduleListResponseSchema } from '../dto/kboScheduleList.dto.js'
import { saveRawSource } from '../repositories/rawSourceRepository.js'

type KboEndpoint = 'GetKboGameDate' | 'GetKboGameList' | 'GetScheduleList' | 'TeamRankDaily' | 'LiveTextView2'

const BASE_URL = 'https://www.koreabaseball.com/ws'
const LIVE_TEXT_URL = 'https://www.koreabaseball.com/Game/LiveTextView2.aspx'
const LIVE_TEXT_REFERER = 'https://www.koreabaseball.com/Game/LiveText.aspx'

type LiveTextViewRequest = {
  readonly gameId: string
  readonly gyear: string
  readonly leagueId?: string
  readonly seriesId?: string
}

export class KboSourceError extends Error {
  readonly endpoint: KboEndpoint
  readonly statusCode?: number

  constructor(endpoint: KboEndpoint, message: string, options: { statusCode?: number, cause?: unknown } = {}) {
    super(`${endpoint}: ${message}`, { cause: options.cause })
    this.name = 'KboSourceError'
    this.endpoint = endpoint
    this.statusCode = options.statusCode
  }
}

function formRequestKey(payload: Record<string, string>): string {
  return new URLSearchParams(
    Object.entries(payload)
      .sort(([lhs], [rhs]) => lhs.localeCompare(rhs))
  ).toString()
}

function recordRawSource(input: {
  endpoint: KboEndpoint
  requestKey: string
  statusCode?: number
  body: string
}): void {
  try {
    saveRawSource({
      source: 'kbo-official',
      endpoint: input.endpoint,
      requestKey: input.requestKey,
      statusCode: input.statusCode,
      body: input.body
    })
  } catch {
    // Raw source persistence is observability data. Source fetch behavior must stay independent.
  }
}

async function postForm<T>(endpoint: KboEndpoint, path: string, payload: Record<string, string>, referer?: string): Promise<T> {
  const response = await fetch(`${BASE_URL}/${path}`, {
    method: 'POST',
    headers: buildKboHeaders(referer),
    body: new URLSearchParams(payload)
  })

  const text = await response.text()
  const trimmed = text.trim()
  recordRawSource({
    endpoint,
    requestKey: formRequestKey(payload),
    statusCode: response.status,
    body: text
  })

  if (!response.ok) {
    throw new KboSourceError(endpoint, `HTTP ${response.status}`, {
      statusCode: response.status
    })
  }

  if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html') || trimmed.includes('<title>에러')) {
    throw new KboSourceError(endpoint, 'returned HTML error page')
  }

  try {
    return JSON.parse(trimmed) as T
  } catch (error) {
    throw new KboSourceError(endpoint, 'returned invalid JSON', { cause: error })
  }
}

export async function fetchKboGameDate(date: string) {
  const json = await postForm('GetKboGameDate', 'Main.asmx/GetKboGameDate', {
    leId: '1',
    srId: '0,1,3,4,5,7,8,9',
    date
  })

  try {
    return rawKboGameDateResponseSchema.parse(json)
  } catch (error) {
    throw new KboSourceError('GetKboGameDate', 'response did not match expected schema', { cause: error })
  }
}

export async function fetchKboGameList(date: string) {
  const json = await postForm('GetKboGameList', 'Main.asmx/GetKboGameList', {
    leId: '1',
    srId: '0,1,3,4,5,7,8,9',
    date
  })

  try {
    return rawKboGameListResponseSchema.parse(json)
  } catch (error) {
    throw new KboSourceError('GetKboGameList', 'response did not match expected schema', { cause: error })
  }
}

export async function fetchKboLiveTextView(input: LiveTextViewRequest): Promise<string> {
  const payload = {
    leagueId: input.leagueId ?? '1',
    seriesId: input.seriesId ?? '0',
    gameId: input.gameId,
    gyear: input.gyear
  }
  const response = await fetch(LIVE_TEXT_URL, {
    method: 'POST',
    headers: buildKboHeaders(`${LIVE_TEXT_REFERER}?leagueId=${payload.leagueId}&seriesId=${payload.seriesId}&gameId=${payload.gameId}&gyear=${payload.gyear}`),
    body: new URLSearchParams(payload),
    signal: AbortSignal.timeout(5_000)
  })
  const text = await response.text()
  const trimmed = text.trim()

  recordRawSource({
    endpoint: 'LiveTextView2',
    requestKey: formRequestKey(payload),
    statusCode: response.status,
    body: text
  })

  if (!response.ok) {
    throw new KboSourceError('LiveTextView2', `HTTP ${response.status}`, {
      statusCode: response.status
    })
  }

  if (trimmed.length === 0 || trimmed.includes('<title>에러')) {
    throw new KboSourceError('LiveTextView2', 'returned invalid HTML')
  }

  return text
}

export async function fetchKboScheduleList(seasonId: string, gameMonth: string) {
  const json = await postForm('GetScheduleList', 'Schedule.asmx/GetScheduleList', {
    leId: '1',
    srIdList: '0,9,6',
    seasonId,
    gameMonth,
    teamId: ''
  }, 'https://www.koreabaseball.com/Schedule/Schedule.aspx')

  try {
    return rawKboScheduleListResponseSchema.parse(json)
  } catch (error) {
    throw new KboSourceError('GetScheduleList', 'response did not match expected schema', { cause: error })
  }
}

export async function fetchKboTeamRankDailyPage(date: string) {
  const url = new URL('https://www.koreabaseball.com/Record/TeamRank/TeamRankDaily.aspx')
  url.searchParams.set('date', date)

  const response = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0',
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      Referer: 'https://www.koreabaseball.com/Record/TeamRank/TeamRankDaily.aspx'
    }
  })

  const text = await response.text()
  recordRawSource({
    endpoint: 'TeamRankDaily',
    requestKey: url.searchParams.toString(),
    statusCode: response.status,
    body: text
  })

  if (!response.ok) {
    throw new KboSourceError('TeamRankDaily', `HTTP ${response.status}`, {
      statusCode: response.status
    })
  }

  if (text.trim().length === 0 || text.includes('<title>에러')) {
    throw new KboSourceError('TeamRankDaily', 'returned invalid HTML')
  }

  return text
}
