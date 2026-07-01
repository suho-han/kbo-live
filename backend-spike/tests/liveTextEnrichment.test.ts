import { beforeEach, describe, expect, it, vi } from 'vitest'

import { fetchKboLiveTextView } from '../src/clients/kboClient.js'
import { enrichPreviousAtBatResult } from '../src/services/liveTextEnrichment.js'
import type { NormalizedGame } from '../src/models/normalizedGame.js'

vi.mock('../src/clients/kboClient.js', () => ({
  fetchKboLiveTextView: vi.fn()
}))

const mockLiveTextView = vi.mocked(fetchKboLiveTextView)
const requestedDate = '20260627'

function makeGame(overrides: Partial<NormalizedGame> = {}): NormalizedGame {
  return {
    gameId: '20260627HTOB0',
    date: requestedDate,
    venue: '잠실',
    startTime: '17:00',
    broadcastChannels: [],
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
      id: 'HT',
      name: 'KIA'
    },
    homeTeam: {
      id: 'OB',
      name: '두산'
    },
    score: {
      away: 0,
      home: 0
    },
    inning: {
      number: 3,
      half: 'bottom'
    },
    count: {
      balls: 2,
      strikes: 2,
      outs: 0
    },
    bases: {
      first: false,
      second: false,
      third: false
    },
    current: {
      batter: '박찬호',
      pitcher: '시라카와'
    },
    probablePitchers: {
      away: {
        name: null,
        record: null
      },
      home: {
        name: null,
        record: null
      }
    },
    recentPlay: null,
    teamRecords: null,
    boxScore: null,
    lineupPreview: null,
    analysis: null,
    sourceMeta: {
      rawStatusCode: '2',
      rawTopBottomCode: 'B',
      fetchedAt: '2026-06-27T08:00:00.000Z'
    },
    ...overrides
  }
}

describe('enrichPreviousAtBatResult', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockLiveTextView.mockResolvedValue('')
  })

  it('enriches requested-date live games with the previous at-bat result', async () => {
    mockLiveTextView.mockResolvedValue(`
      <span class="normaiflTxt"> 9번타자 박찬호<br /></span>
      <span class="normaiflTxt"> 박찬호 : 3루수 땅볼 아웃 (3루수-&gt;1루수 송구아웃)<br /></span>
    `)

    const game = await enrichPreviousAtBatResult(makeGame(), requestedDate)

    expect(mockLiveTextView).toHaveBeenCalledWith({
      gameId: '20260627HTOB0',
      gyear: '2026'
    })
    expect(game.recentPlay).toBe('박찬호 : 3루수 땅볼 아웃 (3루수->1루수 송구아웃)')
  })

  it('does not fetch live text for non-requested-date games', async () => {
    const game = await enrichPreviousAtBatResult(makeGame({ date: '20260628' }), requestedDate)

    expect(mockLiveTextView).not.toHaveBeenCalled()
    expect(game.recentPlay).toBeNull()
  })

  it('does not fetch live text for games that are not live', async () => {
    const game = await enrichPreviousAtBatResult(makeGame({ status: 'final' }), requestedDate)

    expect(mockLiveTextView).not.toHaveBeenCalled()
    expect(game.recentPlay).toBeNull()
  })

  it('keeps live games available without synthetic recentPlay when live text fails', async () => {
    mockLiveTextView.mockRejectedValue(new Error('source down'))

    const game = await enrichPreviousAtBatResult(makeGame(), requestedDate)

    expect(game).toMatchObject({
      gameId: '20260627HTOB0',
      status: 'live',
      recentPlay: null
    })
  })
})
