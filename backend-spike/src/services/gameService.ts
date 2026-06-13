import { fetchKboGameDate, fetchKboGameList, fetchKboScheduleList } from '../clients/kboClient.js'
import { mapGame, mapScheduledGame } from '../mappers/gameMapper.js'
import { mapScheduleGames } from '../mappers/scheduleMapper.js'
import { toKboDate } from '../utils/date.js'
import type { NormalizedGame } from '../models/normalizedGame.js'

async function loadMonthGames(kboDate: string) {
  const [gameDate, scheduleList] = await Promise.all([
    fetchKboGameDate(kboDate),
    fetchKboScheduleList(kboDate.slice(0, 4), kboDate.slice(4, 6))
  ])
  const scheduleGames = mapScheduleGames(scheduleList)
    .filter((game) => game.date.startsWith(kboDate.slice(0, 6)))
  const scheduleByGameId = new Map(scheduleGames.map((game) => [game.gameId, game]))
  const dates = [...new Set([kboDate, ...scheduleGames.map((game) => game.date)])].sort()
  const gameLists = await Promise.all(
    dates.map(async (date) => ({
      date,
      gameList: await fetchKboGameList(date)
    }))
  )

  const gamesById = new Map<string, NormalizedGame>()
  for (const { gameList } of gameLists) {
    for (const game of gameList.game) {
      gamesById.set(game.G_ID, mapGame(game, scheduleByGameId.get(game.G_ID)))
    }
  }

  for (const scheduleGame of scheduleGames) {
    if (!gamesById.has(scheduleGame.gameId)) {
      gamesById.set(scheduleGame.gameId, mapScheduledGame(scheduleGame))
    }
  }

  return {
    gameDate,
    scheduleList,
    scheduleGames,
    gameLists,
    games: [...gamesById.values()].sort((lhs, rhs) => {
      const lhsStart = lhs.startTime ?? lhs.date
      const rhsStart = rhs.startTime ?? rhs.date
      if (lhsStart !== rhsStart) {
        return lhsStart.localeCompare(rhsStart)
      }

      return lhs.gameId.localeCompare(rhs.gameId)
    })
  }
}

export async function getTodayGames(date?: string) {
  const kboDate = toKboDate(date)
  const { games } = await loadMonthGames(kboDate)

  return {
    date: kboDate,
    games
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
  const { gameDate, scheduleList, scheduleGames, gameLists, games } = await loadMonthGames(kboDate)
  const requestedGameList = gameLists.find((entry) => entry.date === kboDate)?.gameList ?? { game: [] }

  return {
    requestedDate: kboDate,
    gameDate,
    gameList: requestedGameList,
    gameLists,
    scheduleList,
    scheduleGames,
    normalizedGames: games
  }
}
