import type { FastifyInstance } from 'fastify'

import { getGameById, getTodayGames, getTodayGamesRaw } from '../services/gameService.js'

export function registerGamesRoutes(server: FastifyInstance) {
  const todayGamesHandler = async (request: { query: unknown }) => {
    const query = request.query as { date?: string }
    return getTodayGames(query.date)
  }

  const gameDetailHandler = async (request: { params: unknown, query: unknown }) => {
    const params = request.params as { gameId: string }
    const query = request.query as { date?: string }
    return getGameById(params.gameId, query.date)
  }

  server.get('/games/today', todayGamesHandler)
  server.get('/v1/games/today', todayGamesHandler)
  server.get('/games/:gameId', gameDetailHandler)
  server.get('/v1/games/:gameId', gameDetailHandler)

  server.get('/debug/source/today', async (request) => {
    const query = request.query as { date?: string }
    return getTodayGamesRaw(query.date)
  })
}
