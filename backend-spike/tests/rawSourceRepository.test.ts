import { mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'

import { closeDatabase, defaultDatabasePath, isDatabaseDisabled, openDatabase, resolveDatabasePath } from '../src/db/database.js'
import { countRawSources, saveRawSource } from '../src/repositories/rawSourceRepository.js'

describe('rawSourceRepository', () => {
  const tempDirs: string[] = []

  afterEach(() => {
    closeDatabase()
    for (const dir of tempDirs.splice(0)) {
      rmSync(dir, { recursive: true, force: true })
    }
    delete process.env.BASEBALL_LIVE_KR_DB_DISABLED
    delete process.env.BASEBALL_LIVE_KR_DB_ENABLED
    delete process.env.BASEBALL_LIVE_KR_DB_PATH
  })

  it('runs migrations and stores deduplicated raw source bodies', () => {
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-db-'))
    tempDirs.push(dir)
    const db = openDatabase(join(dir, 'test.sqlite'))

    const first = saveRawSource({
      source: 'kbo-official',
      endpoint: 'GetKboGameList',
      requestKey: 'date=20260613',
      statusCode: 200,
      body: '{"game":[]}',
      fetchedAt: '2026-06-18T00:00:00.000Z'
    }, db)
    const second = saveRawSource({
      source: 'kbo-official',
      endpoint: 'GetKboGameList',
      requestKey: 'date=20260613',
      statusCode: 200,
      body: '{"game":[]}',
      fetchedAt: '2026-06-18T00:00:01.000Z'
    }, db)

    expect(first?.id).toBeTruthy()
    expect(second?.id).toBe(first?.id)
    expect(countRawSources(db)).toBe(1)
  })

  it('skips persistence when DB is disabled', () => {
    process.env.BASEBALL_LIVE_KR_DB_DISABLED = '1'
    const dir = mkdtempSync(join(tmpdir(), 'kbo-live-db-'))
    tempDirs.push(dir)
    const db = openDatabase(join(dir, 'test.sqlite'))

    const result = saveRawSource({
      source: 'kbo-official',
      endpoint: 'GetKboGameDate',
      requestKey: 'date=20260613',
      body: '{}'
    }, db)

    expect(result).toBeNull()
    expect(countRawSources(db)).toBe(0)
  })

  it('falls back to default DB path when env path is blank', () => {
    process.env.BASEBALL_LIVE_KR_DB_PATH = '   '
    process.env.BASEBALL_LIVE_KR_DB_ENABLED = 'not-a-boolean'

    expect(resolveDatabasePath()).toBe(defaultDatabasePath())
    expect(isDatabaseDisabled()).toBe(true)
  })
})
