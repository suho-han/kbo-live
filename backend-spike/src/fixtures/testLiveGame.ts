import type { NormalizedGame } from '../models/normalizedGame.js'

export function makeTestLiveGame(date: string, fetchedAt = new Date().toISOString()): NormalizedGame {
  const year = date.slice(0, 4)
  const month = date.slice(4, 6)
  const day = date.slice(6, 8)

  return {
    gameId: `${date}LTHH0`,
    date,
    venue: '대전',
    startTime: `${year}-${month}-${day}T18:30:00.000+09:00`,
    broadcastChannels: ['TEST'],
    homepageLinks: {
      gameCenter: null,
      preview: null,
      review: null,
      highlight: null
    },
    pitcherDecisions: {
      win: null,
      loss: null,
      save: null
    },
    status: 'live',
    starterStatus: 'ready',
    awayTeam: {
      id: 'LT',
      name: '롯데'
    },
    homeTeam: {
      id: 'HH',
      name: '한화'
    },
    score: {
      away: 12,
      home: 9
    },
    inning: {
      number: 7,
      half: 'bottom'
    },
    count: {
      balls: 2,
      strikes: 1,
      outs: 1
    },
    bases: {
      first: true,
      second: true,
      third: false
    },
    current: {
      batter: '노시환',
      pitcher: '김원중'
    },
    probablePitchers: {
      away: {
        name: '반즈',
        record: null
      },
      home: {
        name: '문동주',
        record: null
      }
    },
    recentPlay: '7회말 한화 공격, 1사 1,2루에서 노시환 타석',
    teamRecords: {
      away: {
        wins: 32,
        losses: 35,
        draws: 1,
        rank: 8,
        streak: '1승'
      },
      home: {
        wins: 38,
        losses: 29,
        draws: 1,
        rank: 3,
        streak: '2승'
      }
    },
    boxScore: {
      away: {
        runs: 12,
        hits: 14,
        errors: 1,
        walks: 5
      },
      home: {
        runs: 9,
        hits: 11,
        errors: 0,
        walks: 4
      },
      linescore: [
        { inning: 1, away: 2, home: 0 },
        { inning: 2, away: 0, home: 3 },
        { inning: 3, away: 4, home: 1 },
        { inning: 4, away: 1, home: 0 },
        { inning: 5, away: 3, home: 2 },
        { inning: 6, away: 2, home: 1 },
        { inning: 7, away: 0, home: null }
      ]
    },
    lineupPreview: {
      away: ['윤동희', '고승민', '레이예스'],
      home: ['문현빈', '페라자', '노시환']
    },
    analysis: {
      awaySummary: '롯데는 두 자리 득점 이후 불펜 운영이 관건입니다.',
      homeSummary: '한화는 장타 한 방이면 추격 흐름을 이어갈 수 있습니다.',
      keyPoints: ['두 자리 점수 표시 검증', '1사 1,2루', '7회말 진행 중']
    },
    sourceMeta: {
      rawStatusCode: 'TEST_LIVE',
      rawTopBottomCode: 'B',
      fetchedAt
    }
  }
}
