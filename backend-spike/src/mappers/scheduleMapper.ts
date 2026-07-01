import type { RawKboScheduleListResponse } from '../dto/kboScheduleList.dto.js'
import { mapTeamNameToId } from './teamIdMapper.js'

const KBO_HOME = 'https://www.koreabaseball.com'

export interface ScheduleGameInfo {
  gameId: string
  date: string
  awayTeam: {
    id: string
    name: string
  }
  homeTeam: {
    id: string
    name: string
  }
  startTime: string | null
  venue: string | null
  broadcastChannels: string[]
  note: string | null
  links: {
    gameCenter: string | null
    preview: string | null
    review: string | null
    highlight: string | null
  }
  statusHint: 'scheduled' | 'cancelled' | 'delayed' | null
}

interface GameCenterLink {
  href: string
  gameId: string
  gameDate: string
  section: string | null
}

function stripHtml(value: string | null | undefined): string {
  return String(value ?? '')
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&#39;/gi, "'")
    .replace(/&quot;/gi, '"')
    .replace(/\s+/g, ' ')
    .trim()
}

function emptyToNull(value: string | null | undefined): string | null {
  const trimmed = stripHtml(value)
  return trimmed === '' || trimmed === '-' ? null : trimmed
}

function absoluteUrl(href: string): string {
  return href.startsWith('http') ? href : `${KBO_HOME}${href}`
}

function parseGameCenterLinks(text: string | null | undefined): GameCenterLink[] {
  const html = String(text ?? '')
  const links: GameCenterLink[] = []
  const hrefPattern = /href=(['"])(.*?)\1/gi
  let match: RegExpExecArray | null

  while ((match = hrefPattern.exec(html)) !== null) {
    const href = match[2].replaceAll('&amp;', '&')
    const gameId = /[?&]gameId=([^&]+)/i.exec(href)?.[1]
    const gameDate = /[?&]gameDate=([^&]+)/i.exec(href)?.[1]

    if (!gameId || !gameDate) {
      continue
    }

    links.push({
      href: absoluteUrl(href),
      gameId,
      gameDate,
      section: /[?&]section=([^&]+)/i.exec(href)?.[1] ?? null
    })
  }

  return links
}

function normalizeStartTime(date: string, timeText: string | null | undefined): string | null {
  const time = /(\d{1,2}):(\d{2})/.exec(stripHtml(timeText))
  if (!time) {
    return null
  }

  return `${date}T${time[1].padStart(2, '0')}:${time[2]}:00+09:00`
}

function parseDateCell(
  value: string | null | undefined,
  contextDate: string | null,
  seasonId?: string
): string | null {
  const date = /(\d{2})\.(\d{2})/.exec(stripHtml(value))
  const year = seasonId ?? contextDate?.slice(0, 4)

  if (!date || !year) {
    return null
  }

  return `${year}${date[1]}${date[2]}`
}

function firstNonEmpty(values: Array<string | null | undefined>): string | null {
  for (const value of values) {
    const normalized = emptyToNull(value)
    if (normalized) {
      return normalized
    }
  }

  return null
}

function nonEmptyCellTexts(cells: RawKboScheduleListResponse['rows'][number]['row']): string[] {
  return cells
    .map((cell) => emptyToNull(cell.Text))
    .filter((value): value is string => value !== null)
}

function parseBroadcastChannels(value: string | null | undefined): string[] {
  return stripHtml(value)
    .replace(/\s*,\s*/g, ',')
    .split(/[,\s]+/)
    .map((channel) => channel.trim())
    .filter(Boolean)
}

function parseTeamIDs(gameId: string): { away: string, home: string } {
  return {
    away: gameId.slice(8, 10),
    home: gameId.slice(10, 12)
  }
}

function parseTeamNames(value: string | null | undefined): { away: string, home: string } {
  const names = stripHtml(value)
    .split(/\s+vs\s+/i)
    .map((name) => name.trim())
    .filter(Boolean)

  return {
    away: names[0] ?? '',
    home: names[1] ?? ''
  }
}

function statusHint(note: string | null): ScheduleGameInfo['statusHint'] {
  if (!note) {
    return null
  }

  if (note.includes('취소')) {
    return 'cancelled'
  }

  if (note.includes('지연') || note.includes('중단')) {
    return 'delayed'
  }

  return null
}

function inferGameId(
  date: string | null,
  teams: { away: string, home: string }
): string | null {
  if (!date) {
    return null
  }

  const awayId = mapTeamNameToId(teams.away)
  const homeId = mapTeamNameToId(teams.home)
  if (!awayId || !homeId) {
    return null
  }

  return `${date}${awayId}${homeId}0`
}

function parseScheduleRow(
  cells: RawKboScheduleListResponse['rows'][number]['row'],
  fallbackDate: string | null,
  seasonId?: string
): ScheduleGameInfo | null {
  const linkCells = cells
    .map((cell, index) => ({ index, links: parseGameCenterLinks(cell.Text) }))
    .filter((cell) => cell.links.length > 0)

  const primaryLink = linkCells[0]?.links[0]
  const dayCell = cells.find((cell) => cell.Class === 'day')
  const timeCell = cells.find((cell) => cell.Class === 'time')
  const playIndex = cells.findIndex((cell) => cell.Class === 'play')
  const playCell = playIndex >= 0 ? cells[playIndex] : undefined
  const afterPlay = playIndex >= 0 ? cells.slice(playIndex + 1) : []
  const afterLinks = afterPlay.filter((cell) => parseGameCenterLinks(cell.Text).length === 0)
  const infoTexts = nonEmptyCellTexts(afterLinks)
  const links = linkCells.flatMap((cell) => cell.links)
  const linkBySection = new Map(links.map((link) => [link.section, link.href]))
  const note = emptyToNull(afterLinks.at(-1)?.Text)
  const teamNames = parseTeamNames(playCell?.Text)
  const rowDate = parseDateCell(dayCell?.Text, primaryLink?.gameDate ?? fallbackDate, seasonId)
  const date = primaryLink?.gameDate ?? rowDate ?? fallbackDate
  const gameId = primaryLink?.gameId ?? inferGameId(date, teamNames)

  if (!gameId || !date) {
    return null
  }

  const teamIDs = parseTeamIDs(gameId)

  return {
    gameId,
    date,
    awayTeam: {
      id: teamIDs.away,
      name: teamNames.away
    },
    homeTeam: {
      id: teamIDs.home,
      name: teamNames.home
    },
    startTime: normalizeStartTime(date, timeCell?.Text),
    venue: firstNonEmpty([infoTexts.length >= 3 ? infoTexts.at(-2) : infoTexts.at(-1), afterLinks.at(-2)?.Text]),
    broadcastChannels: parseBroadcastChannels(infoTexts[0]),
    note,
    links: {
      gameCenter: primaryLink?.href ?? null,
      preview: linkBySection.get('START_PIT') ?? null,
      review: linkBySection.get('REVIEW') ?? null,
      highlight: linkBySection.get('HIGHLIGHT') ?? null
    },
    statusHint: statusHint(note)
  }
}

export function mapScheduleGames(scheduleList: RawKboScheduleListResponse, seasonId?: string): ScheduleGameInfo[] {
  const games: ScheduleGameInfo[] = []
  let currentDate: string | null = null

  for (const row of scheduleList.rows) {
    const game = parseScheduleRow(row.row, currentDate, seasonId)
    if (game) {
      currentDate = game.date
      games.push(game)
    }
  }

  return games
}

export function indexScheduleGames(scheduleList: RawKboScheduleListResponse, seasonId?: string): Map<string, ScheduleGameInfo> {
  return new Map(mapScheduleGames(scheduleList, seasonId).map((game) => [game.gameId, game]))
}
