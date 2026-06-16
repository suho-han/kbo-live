import { readFileSync } from 'node:fs'
import path from 'node:path'

import { describe, expect, it } from 'vitest'

import { makeTestLiveGame } from '../src/fixtures/testLiveGame.js'

const CONTRACT_DATE = '20260615'
const CONTRACT_FETCHED_AT = '2026-06-15T12:00:00.000Z'
const SWIFT_CONTRACT_FIXTURE = path.resolve(
  '..',
  'Packages/KboLiveCore/Tests/KboLiveCoreTests/Fixtures/live-test-game-response.json'
)

describe('normalized API contract fixtures', () => {
  it('keeps the backend live test fixture in sync with the Swift DTO fixture', () => {
    const swiftFixture = JSON.parse(readFileSync(SWIFT_CONTRACT_FIXTURE, 'utf8'))
    const backendFixture = {
      date: CONTRACT_DATE,
      games: [makeTestLiveGame(CONTRACT_DATE, CONTRACT_FETCHED_AT)]
    }

    expect(backendFixture).toEqual(swiftFixture)
  })
})
