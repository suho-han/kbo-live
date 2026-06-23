export type ExtraRecordKind = 'team' | 'player' | 'league'

export interface ExtraRecordSource {
  id: string
  kind: ExtraRecordKind
  label: string
  url: string
  priority: 'core' | 'context'
}

export const EXTRA_RECORD_SOURCES: ExtraRecordSource[] = [
  {
    id: 'team-hitter-basic1',
    kind: 'team',
    label: '팀 타격 기본 1',
    url: 'https://www.koreabaseball.com/Record/Team/Hitter/Basic1.aspx',
    priority: 'core'
  },
  {
    id: 'team-hitter-basic2',
    kind: 'team',
    label: '팀 타격 기본 2',
    url: 'https://www.koreabaseball.com/Record/Team/Hitter/Basic2.aspx',
    priority: 'core'
  },
  {
    id: 'team-pitcher-basic1',
    kind: 'team',
    label: '팀 투수 기본 1',
    url: 'https://www.koreabaseball.com/Record/Team/Pitcher/Basic1.aspx',
    priority: 'core'
  },
  {
    id: 'team-pitcher-basic2',
    kind: 'team',
    label: '팀 투수 기본 2',
    url: 'https://www.koreabaseball.com/Record/Team/Pitcher/Basic2.aspx',
    priority: 'core'
  },
  {
    id: 'team-defense-basic',
    kind: 'team',
    label: '팀 수비',
    url: 'https://www.koreabaseball.com/Record/Team/Defense/Basic.aspx',
    priority: 'core'
  },
  {
    id: 'team-runner-basic',
    kind: 'team',
    label: '팀 주루',
    url: 'https://www.koreabaseball.com/Record/Team/Runner/Basic.aspx',
    priority: 'context'
  },
  {
    id: 'player-hitter-basic2',
    kind: 'player',
    label: '선수 타격 기본 2',
    url: 'https://www.koreabaseball.com/Record/Player/HitterBasic/Basic2.aspx',
    priority: 'core'
  },
  {
    id: 'player-hitter-detail1',
    kind: 'player',
    label: '선수 타격 세부 1',
    url: 'https://www.koreabaseball.com/Record/Player/HitterBasic/Detail1.aspx',
    priority: 'core'
  },
  {
    id: 'player-pitcher-basic2',
    kind: 'player',
    label: '선수 투수 기본 2',
    url: 'https://www.koreabaseball.com/Record/Player/PitcherBasic/Basic2.aspx',
    priority: 'core'
  },
  {
    id: 'player-pitcher-detail1',
    kind: 'player',
    label: '선수 투수 세부 1',
    url: 'https://www.koreabaseball.com/Record/Player/PitcherBasic/Detail1.aspx',
    priority: 'core'
  },
  {
    id: 'player-pitcher-detail2',
    kind: 'player',
    label: '선수 투수 세부 2',
    url: 'https://www.koreabaseball.com/Record/Player/PitcherBasic/Detail2.aspx',
    priority: 'core'
  },
  {
    id: 'player-defense-basic',
    kind: 'player',
    label: '선수 수비',
    url: 'https://www.koreabaseball.com/Record/Player/Defense/Basic.aspx',
    priority: 'context'
  },
  {
    id: 'player-runner-basic',
    kind: 'player',
    label: '선수 주루',
    url: 'https://www.koreabaseball.com/Record/Player/Runner/Basic.aspx',
    priority: 'context'
  },
  {
    id: 'league-top5',
    kind: 'league',
    label: '선수 순위 TOP 5',
    url: 'https://www.koreabaseball.com/Record/Ranking/Top5.aspx',
    priority: 'context'
  },
  {
    id: 'league-expected-weekly',
    kind: 'league',
    label: '주간 예상 달성 기록',
    url: 'https://www.koreabaseball.com/Record/Expectation/WeekList.aspx',
    priority: 'context'
  },
  {
    id: 'league-crowd-team',
    kind: 'league',
    label: '구단별 관중 현황',
    url: 'https://www.koreabaseball.com/Record/Crowd/GraphTeam.aspx',
    priority: 'context'
  }
]

export function selectExtraRecordSources(explicit?: string): ExtraRecordSource[] {
  if (!explicit || explicit === 'all') {
    return EXTRA_RECORD_SOURCES
  }

  const requested = explicit.split(',').map((value) => value.trim()).filter(Boolean)
  const validKinds = new Set<ExtraRecordKind>(['team', 'player', 'league'])
  const validIds = new Set(EXTRA_RECORD_SOURCES.map((source) => source.id))
  const unknown = requested.filter((value) => !validKinds.has(value as ExtraRecordKind) && !validIds.has(value))
  if (unknown.length > 0) {
    throw new Error(`Unknown extra record source: ${unknown.join(', ')}`)
  }

  const requestedSet = new Set(requested)
  return EXTRA_RECORD_SOURCES.filter((source) => requestedSet.has(source.id) || requestedSet.has(source.kind))
}
