import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'

import { closeDatabase } from '../src/db/database.js'
import { upsertBattingSeasonRecords, upsertPitchingSeasonRecords } from '../src/repositories/playerRecordRepository.js'
import { buildServer } from '../src/server.js'

describe('games routes players', () => {
  const tempDirs: string[] = []

  afterEach(() => {
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
    delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
    delete process.env.BASEBALL_LIVE_KR_DB_PATH
  })

  it('returns player search and season records through v1 player routes', async () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-player-routes-'))
    tempDirs.push(dir)
    process.env.BASEBALL_LIVE_KR_DB_PATH = join(dir, 'test.sqlite')
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
    expect(JSON.parse(search.body).players).toMatchObject([{ playerId: '66606', playerName: 'CHOI Won Jun' }])
    expect(JSON.parse(season.body).player).toMatchObject({
      playerId: '66606',
      playerName: 'CHOI Won Jun',
      batting: { avg: 0.381, hits: 101 }
    })
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
