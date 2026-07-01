import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'

import { closeDatabase, openDatabase } from '../src/db/database.js'
import { listTeamSeasonRecords, upsertTeamSeasonRecords } from '../src/repositories/teamRecordRepository.js'

describe('teamRecordRepository', () => {
  const tempDirs: string[] = []

  afterEach(() => {
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
    delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
  })

  it('upserts team season records and keeps one row per season date team', () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-team-records-'))
    tempDirs.push(dir)
    const db = openDatabase(join(dir, 'test.sqlite'))

    upsertTeamSeasonRecords('20260618', [{
      teamId: 'LG',
      teamName: 'LG',
      rank: 1,
      wins: 42,
      losses: 25,
      draws: 0,
      winRate: '0.627',
      gamesBack: '0',
      recentTen: '7승0무3패',
      streak: '2승'
    }], db)
    upsertTeamSeasonRecords('20260618', [{
      teamId: 'LG',
      teamName: 'LG',
      rank: 2,
      wins: 43,
      losses: 25,
      draws: 0,
      winRate: '0.632',
      gamesBack: '1',
      recentTen: '8승0무2패',
      streak: '3승'
    }], db)

    expect(listTeamSeasonRecords('20260618', db)).toMatchObject([{
      teamId: 'LG',
      rank: 2,
      wins: 43,
      losses: 25,
      draws: 0,
      winningPercentage: 0.632,
      gamesBehind: '1',
      recent10: '8승0무2패',
      streak: '3승'
    }])
  })
})

