export interface NormalizedGame {
  gameId: string
  date: string
  venue: string | null
  startTime: string | null
  broadcastChannels: string[]
  homepageLinks: {
    gameCenter: string | null
    preview: string | null
    review: string | null
    highlight: string | null
  }
  pitcherDecisions: {
    win: string | null
    loss: string | null
    save: string | null
  }
  status: 'scheduled' | 'live' | 'final' | 'delayed' | 'cancelled' | 'unknown'
  starterStatus: StarterStatus
  awayTeam: {
    id: string
    name: string
  }
  homeTeam: {
    id: string
    name: string
  }
  score: {
    away: number
    home: number
  }
  inning: {
    number: number
    half: 'top' | 'bottom'
  } | null
  count: {
    balls: number
    strikes: number
    outs: number
  } | null
  bases: {
    first: boolean
    second: boolean
    third: boolean
  } | null
  current: {
    batter: string | null
    pitcher: string | null
  } | null
  probablePitchers: {
    away: ProbablePitcherSummary
    home: ProbablePitcherSummary
  }
  recentPlay: string | null
  teamRecords: {
    away: TeamRecordSummary | null
    home: TeamRecordSummary | null
  } | null
  boxScore: {
    away: TeamBoxScore
    home: TeamBoxScore
    linescore: Array<{
      inning: number
      away: number | null
      home: number | null
    }>
  } | null
  lineupPreview: {
    away: string[]
    home: string[]
  } | null
  analysis: {
    awaySummary: string | null
    homeSummary: string | null
    keyPoints: string[]
  } | null
  sourceMeta: {
    rawStatusCode: string | null
    rawTopBottomCode: string | null
    fetchedAt: string
  }
}

export type StarterStatus = 'ready' | 'missing' | 'notDue'

export interface ProbablePitcherSummary {
  name: string | null
  record: PitcherSeasonSummary | null
}

export interface PitcherSeasonSummary {
  wins: number | null
  losses: number | null
  era: number | null
  whip: number | null
}

export interface TeamRecordSummary {
  wins: number
  losses: number
  draws: number
  rank: number | null
  streak: string | null
}

export interface TeamBoxScore {
  runs: number
  hits: number | null
  errors: number | null
  walks: number | null
}
