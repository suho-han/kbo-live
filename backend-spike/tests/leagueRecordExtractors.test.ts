import { describe, expect, it } from 'vitest'

import { parseTopFiveCategories } from '../src/records/leagueRecordExtractors.js'

describe('leagueRecordExtractors', () => {
  it('extracts TOP5 categories with Korean player names', () => {
    const html = `
      <div class="record mr15">
        <div class="title_bar"><span class="title">타율 TOP5</span></div>
        <div class="player_top5"><ol class="rankList">
          <li><span class='rank1 name'><a href="/Record/Player/HitterDetail/Basic.aspx?playerId=66606">최원준</a></span><span class="team">KT</span><span class="rr">0.379</span></li>
          <li><span class='rank2 name'><a href="/Record/Player/HitterDetail/Basic.aspx?playerId=54529">레이예스</a></span><span class="team">롯데</span><span class="rr">0.348</span></li>
        </ol></div>
      </div>`

    expect(parseTopFiveCategories(html)).toEqual([{
      title: '타율 TOP5',
      leaders: [
        { rank: 1, playerId: '66606', playerName: '최원준', teamName: 'KT', value: '0.379' },
        { rank: 2, playerId: '54529', playerName: '레이예스', teamName: '롯데', value: '0.348' }
      ]
    }])
  })
})
