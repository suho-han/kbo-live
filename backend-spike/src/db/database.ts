import { mkdirSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { DatabaseSync } from 'node:sqlite'

import { runMigrations } from './migrations.js'

let sharedDatabase: DatabaseSync | null = null
let sharedDatabasePath: string | null = null

export function defaultDatabasePath(): string {
  return resolve(process.cwd(), '.data/baseball-live-kr.sqlite')
}

export function resolveDatabasePath(): string {
  return process.env.BASEBALL_LIVE_KR_DB_PATH?.trim() || defaultDatabasePath()
}

export function openDatabase(path = resolveDatabasePath()): DatabaseSync {
  if (path !== ':memory:') {
    mkdirSync(dirname(path), { recursive: true })
  }

  const db = new DatabaseSync(path)
  db.exec('pragma foreign_keys = on')
  runMigrations(db)
  return db
}

export function getDatabase(): DatabaseSync {
  const path = resolveDatabasePath()
  if (sharedDatabase && sharedDatabasePath === path) {
    return sharedDatabase
  }

  closeDatabase()
  sharedDatabase = openDatabase(path)
  sharedDatabasePath = path
  return sharedDatabase
}

export function closeDatabase(): void {
  if (!sharedDatabase) {
    return
  }

  sharedDatabase.close()
  sharedDatabase = null
  sharedDatabasePath = null
}

export function isDatabaseDisabled(): boolean {
  if (process.env.BASEBALL_LIVE_KR_DB_ENABLED !== undefined) {
    return process.env.BASEBALL_LIVE_KR_DB_ENABLED !== '1'
  }

  return process.env.BASEBALL_LIVE_KR_DB_DISABLED === '1' || process.env.NODE_ENV === 'test'
}
