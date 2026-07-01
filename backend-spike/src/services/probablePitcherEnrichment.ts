import { getPitcherSeasonSummaryByNameAndTeam } from '../repositories/pitcherSeasonSummaryRepository.js'
import type { NormalizedGame } from '../models/normalizedGame.js'
import type { PitcherSeasonSummaryResult } from '../repositories/pitcherSeasonSummaryRepository.js'

function recordFromSummary(summary: PitcherSeasonSummaryResult | null) {
  return summary == null
    ? null
    : {
        wins: summary.wins,
        losses: summary.losses,
        era: summary.era,
        whip: summary.whip
      }
}

export async function enrichProbablePitcherRecords(game: NormalizedGame): Promise<NormalizedGame> {
  const season = Number(game.date.slice(0, 4))
  if (Number.isFinite(season) === false) {
    return game
  }

  const awayName = game.probablePitchers.away.name
  const homeName = game.probablePitchers.home.name
  const [awayRecord, homeRecord] = await Promise.all([
    awayName
      ? Promise.resolve(getPitcherSeasonSummaryByNameAndTeam(awayName, game.awayTeam.id, season, game.date))
      : Promise.resolve(null),
    homeName
      ? Promise.resolve(getPitcherSeasonSummaryByNameAndTeam(homeName, game.homeTeam.id, season, game.date))
      : Promise.resolve(null)
  ])

  return {
    ...game,
    probablePitchers: {
      away: {
        ...game.probablePitchers.away,
        record: recordFromSummary(awayRecord)
      },
      home: {
        ...game.probablePitchers.home,
        record: recordFromSummary(homeRecord)
      }
    }
  }
}
