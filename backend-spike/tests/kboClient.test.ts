import { afterEach, describe, expect, it, vi } from 'vitest'

import { fetchKboGameDate, fetchKboGameList, KboSourceError } from '../src/clients/kboClient.js'
import { TEST_DATE } from './testConfig.js'

describe('kboClient', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('posts form data and parses a valid game date response', async () => {
    const fetchMock = vi.fn(async (_url: string, init: RequestInit) => {
      expect(init.method).toBe('POST')
      expect(String(init.body)).toContain(`date=${TEST_DATE}`)

      return new Response(JSON.stringify({
        BEFORE_G_DT: '20260612',
        NOW_G_DT: TEST_DATE,
        NOW_G_DT_TEXT: '06.13(토)',
        AFTER_G_DT: '20260614',
        code: '100',
        msg: 'OK'
      }), { status: 200 })
    })
    vi.stubGlobal('fetch', fetchMock)

    const response = await fetchKboGameDate(TEST_DATE)

    expect(response.NOW_G_DT).toBe(TEST_DATE)
    expect(fetchMock).toHaveBeenCalledOnce()
  })

  it('wraps non-2xx source responses with endpoint context', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('{}', { status: 503 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toMatchObject({
      name: 'KboSourceError',
      endpoint: 'GetKboGameList',
      statusCode: 503,
      message: expect.stringContaining('HTTP 503')
    })
  })

  it('rejects HTML error pages before JSON parsing', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('<html><title>에러</title></html>', { status: 200 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toThrow(KboSourceError)
    await expect(fetchKboGameList(TEST_DATE)).rejects.toThrow(/HTML error page/)
  })

  it('wraps malformed JSON responses', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('{not-json', { status: 200 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toMatchObject({
      endpoint: 'GetKboGameList',
      message: expect.stringContaining('invalid JSON')
    })
  })

  it('wraps schema mismatches after parsing', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response(JSON.stringify({ game: 'not-array' }), { status: 200 })))

    await expect(fetchKboGameList(TEST_DATE)).rejects.toMatchObject({
      endpoint: 'GetKboGameList',
      message: expect.stringContaining('expected schema')
    })
  })
})
