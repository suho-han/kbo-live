import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'

import { closeDatabase, openDatabase } from '../src/db/database.js'
import { getPitcherSeasonSummaryByNameAndTeam } from '../src/repositories/pitcherSeasonSummaryRepository.js'
import {
  getPlayerSeasonRecord,
  searchPlayers,
  upsertBattingSeasonRecords,
  upsertPitchingSeasonRecords
} from '../src/repositories/playerRecordRepository.js'

describe('playerRecordRepository', () => {
  const tempDirs: string[] = []

  afterEach(() => {
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
    delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
    delete process.env.BASEBALL_LIVE_KR_DB_PATH
  })

  it('upserts batting and pitching records and reads player season summaries', () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-player-records-'))
    tempDirs.push(dir)
    const db = openDatabase(join(dir, 'test.sqlite'))

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
      avg: 0.381,
      walks: 39,
      strikeouts: 47,
      obp: 0.459,
      slg: 0.529,
      ops: 0.988
    }], db)
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
    }], db)

    expect(searchPlayers('choi', 2026, db)).toMatchObject([{
      playerId: '66606',
      playerName: 'CHOI Won Jun',
      teamId: 'KT',
      season: 2026,
      positionGroup: 'batter'
    }])
    expect(getPlayerSeasonRecord('66606', 2026, '20260618', db)).toMatchObject({
      playerId: '66606',
      playerName: 'CHOI Won Jun',
      season: 2026,
      teamId: 'KT',
      batting: {
        walks: 39,
        strikeouts: 47,
        obp: 0.459,
        slg: 0.529,
        ops: 0.988
      }
    })
    expect(getPlayerSeasonRecord('55633', 2026, '20260618', db)).toMatchObject({
      playerId: '55633',
      playerName: 'OLLER Adam',
      season: 2026,
      teamId: 'HT',
      pitching: {
        era: 2.58,
        innings_pitched_outs: 262,
        walks: 27,
        strikeouts: 92,
        earned_runs: 25,
        whip: 0.95,
        strikeouts_per_nine: 9.48,
        walks_per_nine: 2.78,
        strikeout_walk_ratio: 3.41,
        opponent_obp: 0.260,
        opponent_slg: 0.275,
        opponent_ops: 0.535
      }
    })
  })

  it('resolves probable starter pitching summaries by exact team and season', () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-probable-pitchers-'))
    tempDirs.push(dir)
    const db = openDatabase(join(dir, 'test.sqlite'))

    upsertPitchingSeasonRecords('20260617', [{
      playerId: '55633',
      playerName: '올러',
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
      whip: 0.95
    }, {
      playerId: '99100',
      playerName: '올러',
      teamId: 'LG',
      teamName: 'LG',
      rank: 9,
      games: 4,
      completeGames: 0,
      shutouts: 0,
      wins: 1,
      losses: 2,
      saves: 0,
      holds: 0,
      winningPercentage: 0.333,
      plateAppearances: 88,
      pitches: 310,
      inningsPitchedOuts: 58,
      hitsAllowed: 20,
      doublesAllowed: 4,
      triplesAllowed: 0,
      homeRunsAllowed: 2,
      era: 5.12,
      walks: 9,
      strikeouts: 21,
      earnedRuns: 11,
      whip: 1.48
    }], db)

    expect(getPitcherSeasonSummaryByNameAndTeam('올러', 'HT', 2026, '20260618', db)).toMatchObject({
      playerId: '55633',
      playerName: '올러',
      teamId: 'HT',
      season: 2026,
      wins: 7,
      losses: 5,
      era: 2.58,
      whip: 0.95
    })
    expect(getPitcherSeasonSummaryByNameAndTeam('올러', 'LG', 2026, '20260618', db)).toMatchObject({
      playerId: '99100',
      teamId: 'LG',
      era: 5.12,
      whip: 1.48
    })
    expect(getPitcherSeasonSummaryByNameAndTeam('올러', 'SS', 2026, '20260618', db)).toBeNull()
    expect(getPitcherSeasonSummaryByNameAndTeam('없는선수', 'HT', 2026, '20260618', db)).toBeNull()
  })

  it('does not open the configured database for probable pitcher summaries when DB is explicitly disabled', () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-probable-pitcher-disable-'))
    tempDirs.push(dir)
    const path = join(dir, 'test.sqlite')
    const db = openDatabase(path)

    upsertPitchingSeasonRecords('20260701', [{
      playerId: '55633',
      playerName: '올러',
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
      whip: 0.95
    }], db)
    db.close()
    closeDatabase()

    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '0'
    process.env.BASEBALL_LIVE_KR_DB_PATH = path

    expect(getPitcherSeasonSummaryByNameAndTeam('올러', 'HT', 2026, '20260701')).toBeNull()
  })
})
