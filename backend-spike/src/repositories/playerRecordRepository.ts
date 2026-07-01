import type { DatabaseSync } from 'node:sqlite'

import { getDatabase, isDatabaseDisabled } from '../db/database.js'
import type { BattingLeaderEntry, PitchingLeaderEntry } from '../mappers/playerLeaderMapper.js'

export interface PlayerSearchResult {
  playerId: string
  playerName: string
  teamId: string | null
  season: number | null
  positionGroup: 'batter' | 'pitcher' | 'twoWay' | null
}

export interface PlayerSeasonRecordResult {
  playerId: string
  playerName: string
  season: number
  teamId: string
  batting: Record<string, unknown> | null
  pitching: Record<string, unknown> | null
}

function normalizeName(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, ' ')
}

function seasonFromDate(date: string): number {
  return Number(date.slice(0, 4))
}

function upsertPlayerAndTeam(
  db: DatabaseSync,
  input: { playerId: string, playerName: string, teamId: string, teamName: string, season: number, position: 'batter' | 'pitcher' },
  now: string
): void {
  db.prepare(`
    insert into teams (id, short_name, full_name, normalized_name, created_at, updated_at)
    values (?, ?, ?, ?, ?, ?)
    on conflict(id) do update set
      short_name = excluded.short_name,
      full_name = excluded.full_name,
      normalized_name = excluded.normalized_name,
      updated_at = excluded.updated_at
  `).run(input.teamId, input.teamName, input.teamName, normalizeName(input.teamName), now, now)

  db.prepare(`
    insert into players (id, name, normalized_name, created_at, updated_at)
    values (?, ?, ?, ?, ?)
    on conflict(id) do update set
      name = excluded.name,
      normalized_name = excluded.normalized_name,
      updated_at = excluded.updated_at
  `).run(input.playerId, input.playerName, normalizeName(input.playerName), now, now)

  db.prepare(`
    insert into player_team_seasons (player_id, team_id, season, position, created_at, updated_at)
    values (?, ?, ?, ?, ?, ?)
    on conflict(player_id, team_id, season) do update set
      position = case
        when position is null then excluded.position
        when position = excluded.position then position
        else 'twoWay'
      end,
      updated_at = excluded.updated_at
  `).run(input.playerId, input.teamId, input.season, input.position, now, now)
}

export function upsertBattingSeasonRecords(date: string, entries: BattingLeaderEntry[], db?: DatabaseSync): void {
  if (isDatabaseDisabled() || entries.length === 0) {
    return
  }

  const database = db ?? getDatabase()
  const season = seasonFromDate(date)
  const now = new Date().toISOString()
  const upsertRecord = database.prepare(`
    insert into player_batting_season_records (
      season, date, player_id, team_id, rank, games, plate_appearances, at_bats,
      hits, doubles, triples, home_runs, total_bases, rbi, runs, walks, strikeouts,
      stolen_bases, caught_stealing, sacrifice_hits, sacrifice_flies, avg, obp, slg, ops,
      source, raw_source_id, created_at, updated_at
    )
    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    on conflict(season, date, player_id, team_id) do update set
      rank = excluded.rank,
      games = excluded.games,
      plate_appearances = excluded.plate_appearances,
      at_bats = excluded.at_bats,
      hits = excluded.hits,
      doubles = excluded.doubles,
      triples = excluded.triples,
      home_runs = excluded.home_runs,
      total_bases = excluded.total_bases,
      rbi = excluded.rbi,
      runs = excluded.runs,
      walks = excluded.walks,
      strikeouts = excluded.strikeouts,
      stolen_bases = excluded.stolen_bases,
      caught_stealing = excluded.caught_stealing,
      sacrifice_hits = excluded.sacrifice_hits,
      sacrifice_flies = excluded.sacrifice_flies,
      avg = excluded.avg,
      obp = excluded.obp,
      slg = excluded.slg,
      ops = excluded.ops,
      updated_at = excluded.updated_at
  `)

  database.exec('begin')
  try {
    for (const entry of entries) {
      upsertPlayerAndTeam(database, { ...entry, season, position: 'batter' }, now)
      upsertRecord.run(
        season, date, entry.playerId, entry.teamId, entry.rank, entry.games, entry.plateAppearances, entry.atBats,
        entry.hits, entry.doubles, entry.triples, entry.homeRuns, entry.totalBases, entry.rbi, entry.runs, entry.walks ?? null, entry.strikeouts ?? null,
        entry.stolenBases, entry.caughtStealing, entry.sacrificeHits, entry.sacrificeFlies, entry.avg, entry.obp ?? null, entry.slg ?? null, entry.ops ?? null,
        'kbo-official-eng-batting-leaders', null, now, now
      )
    }
    database.exec('commit')
  } catch (error) {
    database.exec('rollback')
    throw error
  }
}

export function upsertPitchingSeasonRecords(date: string, entries: PitchingLeaderEntry[], db?: DatabaseSync): void {
  if (isDatabaseDisabled() || entries.length === 0) {
    return
  }

  const database = db ?? getDatabase()
  const season = seasonFromDate(date)
  const now = new Date().toISOString()
  const upsertRecord = database.prepare(`
    insert into player_pitching_season_records (
      season, date, player_id, team_id, rank, games, games_started, complete_games, shutouts,
      wins, losses, saves, holds, winning_percentage, plate_appearances, pitches, innings_pitched_outs,
      hits_allowed, doubles_allowed, triples_allowed, home_runs_allowed, walks, strikeouts, earned_runs,
      era, whip, strikeouts_per_nine, walks_per_nine, strikeout_walk_ratio, opponent_obp, opponent_slg, opponent_ops,
      source, raw_source_id, created_at, updated_at
    )
    values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    on conflict(season, date, player_id, team_id) do update set
      rank = excluded.rank,
      games = excluded.games,
      complete_games = excluded.complete_games,
      shutouts = excluded.shutouts,
      wins = excluded.wins,
      losses = excluded.losses,
      saves = excluded.saves,
      holds = excluded.holds,
      winning_percentage = excluded.winning_percentage,
      plate_appearances = excluded.plate_appearances,
      pitches = excluded.pitches,
      innings_pitched_outs = excluded.innings_pitched_outs,
      hits_allowed = excluded.hits_allowed,
      doubles_allowed = excluded.doubles_allowed,
      triples_allowed = excluded.triples_allowed,
      home_runs_allowed = excluded.home_runs_allowed,
      walks = excluded.walks,
      strikeouts = excluded.strikeouts,
      earned_runs = excluded.earned_runs,
      era = excluded.era,
      whip = excluded.whip,
      strikeouts_per_nine = excluded.strikeouts_per_nine,
      walks_per_nine = excluded.walks_per_nine,
      strikeout_walk_ratio = excluded.strikeout_walk_ratio,
      opponent_obp = excluded.opponent_obp,
      opponent_slg = excluded.opponent_slg,
      opponent_ops = excluded.opponent_ops,
      updated_at = excluded.updated_at
  `)

  database.exec('begin')
  try {
    for (const entry of entries) {
      upsertPlayerAndTeam(database, { ...entry, season, position: 'pitcher' }, now)
      upsertRecord.run(
        season, date, entry.playerId, entry.teamId, entry.rank, entry.games, null, entry.completeGames, entry.shutouts,
        entry.wins, entry.losses, entry.saves, entry.holds, entry.winningPercentage, entry.plateAppearances, entry.pitches, entry.inningsPitchedOuts,
        entry.hitsAllowed, entry.doublesAllowed, entry.triplesAllowed, entry.homeRunsAllowed, entry.walks ?? null, entry.strikeouts ?? null, entry.earnedRuns ?? null,
        entry.era, entry.whip ?? null, entry.strikeoutsPerNine ?? null, entry.walksPerNine ?? null, entry.strikeoutWalkRatio ?? null,
        entry.opponentObp ?? null, entry.opponentSlg ?? null, entry.opponentOps ?? null,
        'kbo-official-eng-pitching-leaders', null, now, now
      )
    }
    database.exec('commit')
  } catch (error) {
    database.exec('rollback')
    throw error
  }
}

export function searchPlayers(query: string, season?: number, db?: DatabaseSync): PlayerSearchResult[] {
  if (db == null && isDatabaseDisabled()) {
    return []
  }

  const database = db ?? getDatabase()
  const normalizedQuery = `%${normalizeName(query)}%`
  const sql = `
    select
      p.id as playerId,
      p.name as playerName,
      pts.team_id as teamId,
      pts.season as season,
      pts.position as positionGroup
    from players p
    left join player_team_seasons pts on pts.player_id = p.id
    where p.normalized_name like ?
      ${season == null ? '' : 'and pts.season = ?'}
    order by pts.season desc, p.name asc
    limit 30
  `
  const rows = season == null
    ? database.prepare(sql).all(normalizedQuery)
    : database.prepare(sql).all(normalizedQuery, season)
  return rows as unknown as PlayerSearchResult[]
}

export function getPlayerSeasonRecord(
  playerId: string,
  season: number,
  date?: string,
  db?: DatabaseSync
): PlayerSeasonRecordResult | null {
  if (db == null && isDatabaseDisabled()) {
    return null
  }

  const database = db ?? getDatabase()
  const player = database.prepare('select id as playerId, name as playerName from players where id = ?')
    .get(playerId) as { playerId: string, playerName: string } | undefined
  if (!player) {
    return null
  }

  const datePredicate = date == null ? '' : 'and date <= ?'
  const battingArgs = date == null ? [season, playerId] : [season, playerId, date]
  const pitchingArgs = date == null ? [season, playerId] : [season, playerId, date]
  const batting = database.prepare(`
    select * from player_batting_season_records
    where season = ? and player_id = ? ${datePredicate}
    order by date desc
    limit 1
  `).get(...battingArgs) as Record<string, unknown> | undefined
  const pitching = database.prepare(`
    select * from player_pitching_season_records
    where season = ? and player_id = ? ${datePredicate}
    order by date desc
    limit 1
  `).get(...pitchingArgs) as Record<string, unknown> | undefined
  const teamId = String((batting?.team_id ?? pitching?.team_id ?? '') || '')

  return {
    ...player,
    season,
    teamId,
    batting: batting ?? null,
    pitching: pitching ?? null
  }
}
