import type { DatabaseSync } from 'node:sqlite'

import { getDatabase, isDatabaseDisabled } from '../db/database.js'

export interface PitcherSeasonSummaryResult {
  playerId: string
  playerName: string
  teamId: string
  season: number
  wins: number | null
  losses: number | null
  era: number | null
  whip: number | null
  date: string
}

function normalizeName(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, ' ')
}

export function getPitcherSeasonSummaryByNameAndTeam(
  playerName: string,
  teamId: string,
  season: number,
  date?: string,
  db?: DatabaseSync
): PitcherSeasonSummaryResult | null {
  if (db == null && isDatabaseDisabled()) {
    return null
  }

  const normalizedName = normalizeName(playerName)
  if (normalizedName === '' || teamId.trim() === '') {
    return null
  }

  const database = db ?? getDatabase()
  const datePredicate = date == null ? '' : 'and ppsr.date <= ?'
  const rows = database.prepare(`
    select
      p.id as playerId,
      p.name as playerName,
      ppsr.team_id as teamId,
      ppsr.season as season,
      ppsr.wins as wins,
      ppsr.losses as losses,
      ppsr.era as era,
      ppsr.whip as whip,
      ppsr.date as date
    from players p
    join player_team_seasons pts
      on pts.player_id = p.id
     and pts.team_id = ?
     and pts.season = ?
     and pts.position in ('pitcher', 'twoWay')
    join player_pitching_season_records ppsr
      on ppsr.player_id = p.id
     and ppsr.team_id = pts.team_id
     and ppsr.season = pts.season
    where p.normalized_name = ?
      ${datePredicate}
    order by ppsr.date desc, p.id asc
  `).all(teamId, season, normalizedName, ...(date == null ? [] : [date])) as unknown as Array<PitcherSeasonSummaryResult>

  if (rows.length === 0) {
    return null
  }

  const playerIds = new Set(rows.map((row) => row.playerId))
  if (playerIds.size !== 1) {
    return null
  }

  return rows[0] ?? null
}
