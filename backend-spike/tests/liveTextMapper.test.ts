import { describe, expect, it } from 'vitest'

import { parsePreviousAtBatResult } from '../src/mappers/liveTextMapper.js'

describe('parsePreviousAtBatResult', () => {
  it('returns the newest completed at-bat result from KBO LiveText HTML', () => {
    const html = `
      <span class="normaiflTxt"> 한동희 : 좌익수 플라이 아웃<br /></span>
      <span class="normaiflTxt"> 레이예스 : 2루수 땅볼 아웃 (2루수-&gt;1루수 송구아웃)<br /></span>
      <span class="normaiflTxt"> 박찬호 : 3루수 땅볼 아웃 (3루수-&gt;1루수 송구아웃)<br /></span>
    `

    expect(parsePreviousAtBatResult(html)).toBe('박찬호 : 3루수 땅볼 아웃 (3루수->1루수 송구아웃)')
  })

  it('ignores lineup, inning banner, count, and runner-only lines', () => {
    const html = `
      <span class="normaiflTxt"> 3회말 두산 공격<br /></span>
      <span class="normaiflTxt"> 9번타자 박찬호<br /></span>
      <span class="normaiflTxt"> 0-1 2out<br /></span>
      <span class="normaiflTxt"> 2루주자 황성빈 : 3루까지 진루<br /></span>
      <span class="normaiflTxt"> ball<br /></span>
    `

    expect(parsePreviousAtBatResult(html)).toBeNull()
  })

  it('returns null for blank or malformed HTML without a result line', () => {
    expect(parsePreviousAtBatResult('')).toBeNull()
    expect(parsePreviousAtBatResult('<div>현재 타석 박찬호</div>')).toBeNull()
  })
})
