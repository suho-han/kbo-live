import { describe, expect, it } from 'vitest'

import { EXTRA_RECORD_SOURCES, selectExtraRecordSources } from '../src/records/extraRecordSources.js'

describe('extraRecordSources', () => {
  it('selects all configured sources by default', () => {
    expect(selectExtraRecordSources()).toHaveLength(EXTRA_RECORD_SOURCES.length)
  })

  it('filters sources by kind and explicit id', () => {
    const selected = selectExtraRecordSources('team,player-pitcher-detail2')

    expect(selected.some((source) => source.id === 'team-hitter-basic1')).toBe(true)
    expect(selected.some((source) => source.id === 'player-pitcher-detail2')).toBe(true)
    expect(selected.some((source) => source.kind === 'league')).toBe(false)
  })

  it('rejects unknown --extra-records values', () => {
    expect(() => selectExtraRecordSources('team,typo-id')).toThrow(/Unknown extra record source: typo-id/)
  })
})
