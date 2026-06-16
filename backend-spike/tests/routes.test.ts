import { beforeEach, describe, expect, it, vi } from 'vitest'

import { getGameById, getTodayGames, getTodayGamesRaw } from '../src/services/gameService.js'
import { KboDateInputError } from '../src/utils/date.js'
import { buildServer } from '../src/server.js'
import { TEST_DATE, TEST_GAME_ID, TEST_INPUT_DATE } from './testConfig.js'

vi.mock('../src/services/gameService.js', () => ({
  getTodayGames: vi.fn(),
  getGameById: vi.fn(),
  getTodayGamesRaw: vi.fn()
}))

const mockTodayGames = vi.mocked(getTodayGames)
const mockGameById = vi.mocked(getGameById)
const mockTodayGamesRaw = vi.mocked(getTodayGamesRaw)

describe('games routes', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockTodayGames.mockResolvedValue({ date: TEST_DATE, games: [] })
    mockGameById.mockResolvedValue({ date: TEST_DATE, game: null })
    mockTodayGamesRaw.mockResolvedValue({
      requestedDate: TEST_DATE,
      gameDate: {},
      gameList: { game: [] },
      scheduleList: { rows: [] },
      scheduleGames: [],
      normalizedGames: []
    } as never)
  })

  it('returns today games through Fastify injection', async () => {
    const server = buildServer()

    const response = await server.inject(`/games/today?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ date: TEST_DATE, games: [] })
    expect(mockTodayGames).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('returns today games through the v1 route', async () => {
    const server = buildServer()

    const response = await server.inject(`/v1/games/today?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ date: TEST_DATE, games: [] })
    expect(mockTodayGames).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('returns game detail by id', async () => {
    const server = buildServer()

    const response = await server.inject(`/games/${TEST_GAME_ID}?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ date: TEST_DATE, game: null })
    expect(mockGameById).toHaveBeenCalledWith(TEST_GAME_ID, TEST_INPUT_DATE)
    await server.close()
  })

  it('returns game detail through the v1 route', async () => {
    const server = buildServer()

    const response = await server.inject(`/v1/games/${TEST_GAME_ID}?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ date: TEST_DATE, game: null })
    expect(mockGameById).toHaveBeenCalledWith(TEST_GAME_ID, TEST_INPUT_DATE)
    await server.close()
  })

  it('returns health and readiness payloads through v1 operational routes', async () => {
    const server = buildServer()

    const health = await server.inject('/v1/health')
    const readiness = await server.inject('/v1/ready')

    expect(health.statusCode).toBe(200)
    expect(JSON.parse(health.body)).toMatchObject({
      ok: true,
      source: 'kbo-official-spike'
    })
    expect(readiness.statusCode).toBe(200)
    expect(JSON.parse(readiness.body)).toMatchObject({
      ok: true,
      source: 'kbo-official-spike',
      checks: {
        config: true
      }
    })
    await server.close()
  })

  it('returns debug source payloads', async () => {
    const server = buildServer()

    const response = await server.inject(`/debug/source/today?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body).requestedDate).toBe(TEST_DATE)
    expect(mockTodayGamesRaw).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('maps invalid date errors to 400 responses', async () => {
    mockTodayGames.mockRejectedValue(new KboDateInputError('2026'))
    const server = buildServer()

    const response = await server.inject('/games/today?date=2026')

    expect(response.statusCode).toBe(400)
    expect(JSON.parse(response.body)).toEqual({
      error: {
        code: 'INVALID_DATE',
        message: 'invalid date format: 2026',
        statusCode: 400
      }
    })
    await server.close()
  })

  it('maps unexpected errors to the normalized error shape', async () => {
    mockTodayGames.mockRejectedValue(new Error('source unavailable'))
    const server = buildServer()

    const response = await server.inject('/games/today')

    expect(response.statusCode).toBe(500)
    expect(JSON.parse(response.body)).toEqual({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'source unavailable',
        statusCode: 500
      }
    })
    await server.close()
  })
})
