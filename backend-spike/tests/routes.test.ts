import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import { closeDatabase } from '../src/db/database.js'
import { upsertBattingSeasonRecords, upsertPitchingSeasonRecords } from '../src/repositories/playerRecordRepository.js'
import { getGameById, getTeamStandings, getTodayGames, getTodayGamesRaw } from '../src/services/gameService.js'
import { KboDateInputError } from '../src/utils/date.js'
import { buildServer } from '../src/server.js'
import { TEST_DATE, TEST_GAME_ID, TEST_INPUT_DATE } from './testConfig.js'

vi.mock('../src/services/gameService.js', () => ({
  getTodayGames: vi.fn(),
  getGameById: vi.fn(),
  getTeamStandings: vi.fn(),
  getTodayGamesRaw: vi.fn()
}))

const mockTodayGames = vi.mocked(getTodayGames)
const mockGameById = vi.mocked(getGameById)
const mockTeamStandings = vi.mocked(getTeamStandings)
const mockTodayGamesRaw = vi.mocked(getTodayGamesRaw)
const tempDirs: string[] = []

describe('games routes', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockTodayGames.mockResolvedValue({ date: TEST_DATE, games: [] })
    mockGameById.mockResolvedValue({ date: TEST_DATE, game: null })
    mockTeamStandings.mockResolvedValue({ date: TEST_DATE, standings: [] })
    mockTodayGamesRaw.mockResolvedValue({
      requestedDate: TEST_DATE,
      gameDate: {},
      gameList: { game: [] },
      scheduleList: { rows: [] },
      scheduleGames: [],
      normalizedGames: []
    } as never)
  })

  afterEach(() => {
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
    delete process.env.KBO_DB_ENABLED
    delete process.env.KBO_DB_PATH
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

  it('returns team standings through the v1 route', async () => {
    const server = buildServer()

    const response = await server.inject(`/v1/standings?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ date: TEST_DATE, standings: [] })
    expect(mockTeamStandings).toHaveBeenCalledWith(TEST_INPUT_DATE)
    await server.close()
  })

  it('returns team standings through the explicit teams route', async () => {
    const server = buildServer()

    const response = await server.inject(`/v1/teams/standings?date=${TEST_INPUT_DATE}`)

    expect(response.statusCode).toBe(200)
    expect(JSON.parse(response.body)).toEqual({ date: TEST_DATE, standings: [] })
    expect(mockTeamStandings).toHaveBeenCalledWith(TEST_INPUT_DATE)
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

  it('returns player search and season records through v1 player routes', async () => {
    process.env.KBO_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-player-routes-'))
    tempDirs.push(dir)
    process.env.KBO_DB_PATH = join(dir, 'test.sqlite')
    upsertBattingSeasonRecords('20260618', [{
      playerId: '66606',
      playerName: 'CHOI Won Jun',
      teamId: 'KT',
      teamName: 'KT',
      rank: 1,
      games: 65,
      plateAppearances: 312,
      atBats: 265,
      runs: 59,
      hits: 101,
      doubles: 20,
      triples: 2,
      homeRuns: 5,
      totalBases: 140,
      rbi: 37,
      stolenBases: 15,
      caughtStealing: 6,
      sacrificeHits: 3,
      sacrificeFlies: 3,
      avg: 0.381
    }])
    upsertPitchingSeasonRecords('20260618', [{
      playerId: '55633',
      playerName: 'OLLER Adam',
      teamId: 'HT',
      teamName: 'KIA',
      rank: 1,
      games: 14,
      completeGames: 1,
      shutouts: 1,
      wins: 7,
      losses: 5,
      saves: 0,
      holds: 0,
      winningPercentage: 0.583,
      plateAppearances: 344,
      pitches: 1314,
      inningsPitchedOuts: 262,
      hitsAllowed: 56,
      doublesAllowed: 6,
      triplesAllowed: 2,
      homeRunsAllowed: 6,
      era: 2.58,
      walks: 27,
      strikeouts: 92,
      earnedRuns: 25,
      whip: 0.95,
      strikeoutsPerNine: 9.48,
      walksPerNine: 2.78,
      strikeoutWalkRatio: 3.41,
      opponentObp: 0.260,
      opponentSlg: 0.275,
      opponentOps: 0.535
    }])
    const server = buildServer()

    const search = await server.inject('/v1/players/search?q=won&season=2026')
    const season = await server.inject('/v1/players/66606/season?season=2026&date=20260618')
    const pitcherSeason = await server.inject('/v1/players/55633/season?season=2026&date=20260618')

    expect(search.statusCode).toBe(200)
    expect(JSON.parse(search.body).players).toMatchObject([{ playerId: '66606', playerName: 'CHOI Won Jun' }])
    expect(season.statusCode).toBe(200)
    expect(JSON.parse(season.body).player).toMatchObject({
      playerId: '66606',
      playerName: 'CHOI Won Jun',
      batting: {
        avg: 0.381,
        hits: 101
      }
    })
    expect(pitcherSeason.statusCode).toBe(200)
    expect(JSON.parse(pitcherSeason.body).player).toMatchObject({
      playerId: '55633',
      playerName: 'OLLER Adam',
      pitching: {
        strikeouts_per_nine: 9.48,
        walks_per_nine: 2.78,
        strikeout_walk_ratio: 3.41,
        opponent_obp: 0.260,
        opponent_slg: 0.275,
        opponent_ops: 0.535
      }
    })
    await server.close()
  })
})
