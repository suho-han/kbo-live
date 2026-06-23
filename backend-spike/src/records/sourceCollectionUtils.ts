export interface FetchedText {
  body: string
  fetchedAt: string
  statusCode: number
}

export interface RecordTableMetadata {
  tableCount: number
  rowCount: number
  columns: string[]
}

export type FetchLike = (url: string | URL, init?: RequestInit) => Promise<Response>

export async function fetchTextWithTimeout(
  url: string,
  init: RequestInit = {},
  timeoutMs = 15000,
  fetchImpl: FetchLike = fetch
): Promise<FetchedText> {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), timeoutMs)

  try {
    const response = await fetchImpl(url, {
      ...init,
      signal: controller.signal
    })
    const body = await response.text()
    return {
      body,
      fetchedAt: new Date().toISOString(),
      statusCode: response.status
    }
  } finally {
    clearTimeout(timeout)
  }
}

export function decodeBasicHtml(value: string): string {
  return value
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&#39;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
}

export function stripBasicTags(value: string): string {
  return decodeBasicHtml(value.replace(/<br\s*\/?>/gi, '\n').replace(/<[^>]*>/g, '')).replace(/\s+/g, ' ').trim()
}

export function collectRecordTableMetadata(html: string): RecordTableMetadata {
  const tables = [...html.matchAll(/<table[^>]*>([\s\S]*?)<\/table>/gi)].map((match) => match[0])
  const rowCount = tables.reduce((count, table) => count + [...table.matchAll(/<tbody[\s\S]*?<\/tbody>/gi)]
    .reduce((rows, tbody) => rows + [...tbody[0].matchAll(/<tr\b/gi)].length, 0), 0)
  const firstTable = tables[0] ?? ''
  const columns = [...firstTable.matchAll(/<th[^>]*>([\s\S]*?)<\/th>/gi)]
    .map((match) => stripBasicTags(match[1]))
    .filter(Boolean)

  return {
    tableCount: tables.length,
    rowCount,
    columns
  }
}

export function requireKoreanPlayerNames<T extends { playerId: string, playerName: string }>(
  records: T[],
  names: Map<string, string>,
  kind: string
): T[] {
  const missing = records
    .filter((record) => !names.has(record.playerId))
    .map((record) => record.playerId)

  if (missing.length > 0) {
    throw new Error(`Missing Korean player names for ${kind}: ${missing.join(', ')}`)
  }

  return records.map((record) => ({
    ...record,
    playerName: names.get(record.playerId)!
  }))
}
