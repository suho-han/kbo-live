import { describe, expect, it } from 'vitest'

import { parseKboTeamRankDaily } from '../src/mappers/teamRankMapper.js'

describe('parseKboTeamRankDaily', () => {
  it('maps KBO standings rows into team record summaries', () => {
    const html = `
      <table summary="순위, 팀명,승,패,무,승률,승차,최근10경기,연속,홈,방문">
        <tbody>
          <tr><td>1</td><td>LG</td><td>65</td><td>41</td><td>24</td><td>0</td><td>0.631</td><td>0</td><td>7승0무3패</td><td>2승</td><td>24-0-11</td><td>17-0-13</td></tr>
          <tr><td>4</td><td>KIA</td><td>66</td><td>34</td><td>31</td><td>1</td><td>0.523</td><td>7</td><td>5승0무5패</td><td>1패</td><td>20-1-13</td><td>14-0-18</td></tr>
        </tbody>
      </table>`

    expect(parseKboTeamRankDaily(html)).toEqual([
      {
        teamId: 'LG',
        teamName: 'LG',
        wins: 41,
        losses: 24,
        draws: 0,
        rank: 1,
        streak: '2승',
        winRate: '0.631',
        recentTen: '7승0무3패',
        gamesBack: '0'
      },
      {
        teamId: 'HT',
        teamName: 'KIA',
        wins: 34,
        losses: 31,
        draws: 1,
        rank: 4,
        streak: '1패',
        winRate: '0.523',
        recentTen: '5승0무5패',
        gamesBack: '7'
      }
    ])
  })

  it('maps current KBO table markup without an exact summary match', () => {
    const html = `
      <table summary="순위, 팀명,경기,승,패,무,승률,게임차,최근10경기,연속,홈,방문" class="tData">
        <thead><tr><th>순위</th><th>팀명</th><th>경기</th><th>승</th><th>패</th><th>무</th><th>승률</th><th>게임차</th><th>최근10경기</th><th>연속</th><th>홈</th><th>방문</th></tr></thead>
        <tbody>
          <tr><td>8</td><td>SSG</td><td>65</td><td>27</td><td>37</td><td>1</td><td>0.422</td><td>13.5</td><td>4승0무6패</td><td>2패</td><td>14-1-16</td><td>13-0-21</td></tr>
        </tbody>
      </table>`

    expect(parseKboTeamRankDaily(html)).toEqual([
      {
        teamId: 'SK',
        teamName: 'SSG',
        wins: 27,
        losses: 37,
        draws: 1,
        rank: 8,
        streak: '2패',
        winRate: '0.422',
        recentTen: '4승0무6패',
        gamesBack: '13.5'
      }
    ])
  })
})
