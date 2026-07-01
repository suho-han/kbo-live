import { describe, expect, it } from 'vitest'

import { mapProbablePitcherRecordAnalysis } from '../src/mappers/probablePitcherRecordMapper.js'

describe('probablePitcherRecordMapper', () => {
  it('maps KBO starter analysis rows into pitcher season records', () => {
    const records = mapProbablePitcherRecordAnalysis({
      response: {
        rows: [{
          row: [
            {
              Text: "<div class='pitcher-cell'><span class='name'>사우어</span><div class='record'>시즌 6승 4패<br/></div></div>",
              Class: 'pitcher'
            },
            { Text: '4.48', Class: 'td_era_T' },
            { Text: '15', Class: 'td_game_T' },
            { Text: '1.36', Class: 'td_whip_T' }
          ]
        }, {
          row: [
            {
              Text: "<div class='pitcher-cell'><span class='name'>에르난데스</span><div class='record'>시즌 3승 5패<br/></div></div>",
              Class: 'pitcher'
            },
            { Text: '4.54', Class: 'td_era_B' },
            { Text: '14', Class: 'td_game_B' },
            { Text: '1.44', Class: 'td_whip_B' }
          ]
        }]
      },
      starters: [{
        side: 'away',
        playerId: '56032',
        playerName: '사우어',
        teamId: 'KT',
        teamName: 'KT'
      }, {
        side: 'home',
        playerId: '56712',
        playerName: '에르난데스',
        teamId: 'HH',
        teamName: '한화'
      }]
    })

    expect(records).toEqual([{
      playerId: '56032',
      playerName: '사우어',
      teamId: 'KT',
      teamName: 'KT',
      rank: null,
      games: 15,
      completeGames: null,
      shutouts: null,
      wins: 6,
      losses: 4,
      saves: null,
      holds: null,
      winningPercentage: null,
      plateAppearances: null,
      pitches: null,
      inningsPitchedOuts: null,
      hitsAllowed: null,
      doublesAllowed: null,
      triplesAllowed: null,
      homeRunsAllowed: null,
      era: 4.48,
      whip: 1.36
    }, {
      playerId: '56712',
      playerName: '에르난데스',
      teamId: 'HH',
      teamName: '한화',
      rank: null,
      games: 14,
      completeGames: null,
      shutouts: null,
      wins: 3,
      losses: 5,
      saves: null,
      holds: null,
      winningPercentage: null,
      plateAppearances: null,
      pitches: null,
      inningsPitchedOuts: null,
      hitsAllowed: null,
      doublesAllowed: null,
      triplesAllowed: null,
      homeRunsAllowed: null,
      era: 4.54,
      whip: 1.44
    }])
  })
})
