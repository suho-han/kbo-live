import { describe, expect, it } from 'vitest'

import { collectRecordTableMetadata, fetchTextWithTimeout, requireKoreanPlayerNames } from '../src/records/sourceCollectionUtils.js'

describe('sourceCollectionUtils', () => {
  it('passes an AbortSignal to fetch for timeout protection', async () => {
    let receivedSignal: AbortSignal | undefined
    const fetchImpl = async (_url: string | URL, init?: RequestInit) => {
      receivedSignal = init?.signal ?? undefined
      return new Response('ok', { status: 200 })
    }

    const body = await fetchTextWithTimeout('https://example.test/source', {}, 1000, fetchImpl)

    expect(body.statusCode).toBe(200)
    expect(body.body).toBe('ok')
    expect(receivedSignal).toBeInstanceOf(AbortSignal)
  })

  it('counts tables, rows, and header labels from a record table', () => {
    const metadata = collectRecordTableMetadata(`
      <table>
        <thead><tr><th>순위</th><th>팀명</th><th>AVG</th></tr></thead>
        <tbody><tr><td>1</td><td>LG</td><td>0.300</td></tr><tr><td>2</td><td>KT</td><td>0.290</td></tr></tbody>
      </table>`)

    expect(metadata).toEqual({
      tableCount: 1,
      rowCount: 2,
      columns: ['순위', '팀명', 'AVG']
    })
  })

  it('fails instead of falling back to English names when Korean names are missing', () => {
    expect(() => requireKoreanPlayerNames([
      { playerId: '66606', playerName: 'CHOI Won Jun' },
      { playerId: '54529', playerName: 'REYES Victor' }
    ], new Map([['66606', '최원준']]), 'batting')).toThrow(/Missing Korean player names for batting: 54529/)
  })
})
