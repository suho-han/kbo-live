import type { TeamRecordSummary } from '../models/normalizedGame.js'

export interface TeamRankEntry extends TeamRecordSummary {
  teamId: string
  teamName: string
  winRate: string | null
  recentTen: string | null
  gamesBack: string | null
}

const TEAM_NAME_TO_ID: Record<string, string> = {
  LG: 'LG',
  KT: 'KT',
  삼성: 'SS',
  KIA: 'HT',
  두산: 'OB',
  한화: 'HH',
  NC: 'NC',
  SSG: 'SK',
  키움: 'WO',
  롯데: 'LT'
}

function stripTags(value: string): string {
  return value
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]*>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .trim()
}

function toNumber(value: string): number | null {
  const parsed = Number(value.trim())
  return Number.isFinite(parsed) ? parsed : null
}

export function parseKboTeamRankDaily(html: string): TeamRankEntry[] {
  const standingsTable = html.match(/<table[^>]*(?:summary="[^"]*최근10경기[^"]*"|class="[^"]*\btData\b[^"]*")[^>]*>[\s\S]*?<\/table>/)
  if (!standingsTable) return []

  const rows = [...standingsTable[0].matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/g)]
  return rows.flatMap((rowMatch) => {
    const cells = [...rowMatch[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/g)].map((cell) => stripTags(cell[1]))
    if (cells.length < 10) return []

    const [rankText, teamName, , winsText, lossesText, drawsText, winRate, gamesBack, recentTen, streak] = cells
    const rank = toNumber(rankText)
    const wins = toNumber(winsText)
    const losses = toNumber(lossesText)
    const draws = toNumber(drawsText)
    const teamId = TEAM_NAME_TO_ID[teamName]

    if (!teamId || rank == null || wins == null || losses == null || draws == null) {
      return []
    }

    return [{
      teamId,
      teamName,
      wins,
      losses,
      draws,
      rank,
      streak: streak || null,
      winRate: winRate || null,
      recentTen: recentTen || null,
      gamesBack: gamesBack || null
    }]
  })
}
