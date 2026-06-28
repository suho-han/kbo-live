import type { TeamRankEntry } from '../mappers/teamRankMapper.js'
import type { NormalizedGame, TeamRecordSummary } from '../models/normalizedGame.js'

export function teamRecordsById(standings: TeamRankEntry[]): Map<string, TeamRecordSummary> {
  return new Map(
    standings.map((entry) => [
      entry.teamId,
      {
        wins: entry.wins,
        losses: entry.losses,
        draws: entry.draws,
        rank: entry.rank,
        streak: entry.streak
      }
    ])
  )
}

export function enrichTeamRecords(
  game: NormalizedGame,
  recordsByTeamId: Map<string, TeamRecordSummary>
): NormalizedGame {
  const away = recordsByTeamId.get(game.awayTeam.id) ?? game.teamRecords?.away ?? null
  const home = recordsByTeamId.get(game.homeTeam.id) ?? game.teamRecords?.home ?? null

  if (!away && !home) {
    return game
  }

  return {
    ...game,
    teamRecords: {
      away,
      home
    }
  }
}
