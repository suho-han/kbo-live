import { fetchKboGameDate, fetchKboGameList } from '../clients/kboClient.js'
import { mapGame } from '../mappers/gameMapper.js'
import { toKboDate } from '../utils/date.js'

export async function getTodayGames(date?: string) {
  const kboDate = toKboDate(date)
  const [gameDate, gameList] = await Promise.all([
    fetchKboGameDate(kboDate),
    fetchKboGameList(kboDate)
  ])

  return {
    date: kboDate,
    games: gameList.game.map(mapGame)
  }
}

export async function getGameById(gameId: string, date?: string) {
  const result = await getTodayGames(date)
  return {
    date: result.date,
    game: result.games.find((game) => game.gameId === gameId) ?? null
  }
}

export async function getTodayGamesRaw(date?: string) {
  const kboDate = toKboDate(date)
  const [gameDate, gameList] = await Promise.all([
    fetchKboGameDate(kboDate),
    fetchKboGameList(kboDate)
  ])

  return {
    requestedDate: kboDate,
    gameDate,
    gameList
  }
}
