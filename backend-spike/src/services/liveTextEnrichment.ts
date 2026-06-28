import { fetchKboLiveTextView } from '../clients/kboClient.js'
import { parsePreviousAtBatResult } from '../mappers/liveTextMapper.js'
import type { NormalizedGame } from '../models/normalizedGame.js'

export async function enrichPreviousAtBatResult(game: NormalizedGame, kboDate: string): Promise<NormalizedGame> {
  if (game.date !== kboDate || game.status !== 'live' || game.gameId.trim().length === 0) {
    return game
  }

  try {
    const html = await fetchKboLiveTextView({
      gameId: game.gameId,
      gyear: kboDate.slice(0, 4)
    })

    return {
      ...game,
      recentPlay: parsePreviousAtBatResult(html)
    }
  } catch (error) {
    if (error instanceof Error) {
      return game
    }

    throw error
  }
}
