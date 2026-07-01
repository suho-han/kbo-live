import { stripBasicTags } from '../records/sourceCollectionUtils.js'
import type { PitchingLeaderEntry } from './playerLeaderMapper.js'
import type { RawKboPitcherRecordAnalysisResponse } from '../dto/kboPitcherRecordAnalysis.dto.js'

export type ProbablePitcherSide = 'away' | 'home'

export interface ProbablePitcherStarter {
  readonly side: ProbablePitcherSide
  readonly playerId: string
  readonly playerName: string
  readonly teamId: string
  readonly teamName: string
}

export interface ProbablePitcherRecordAnalysisInput {
  readonly response: Pick<RawKboPitcherRecordAnalysisResponse, 'rows'>
  readonly starters: readonly ProbablePitcherStarter[]
}

type StatClass = 'td_era_T' | 'td_era_B' | 'td_game_T' | 'td_game_B' | 'td_whip_T' | 'td_whip_B'

interface RowStats {
  readonly era: number | null
  readonly games: number | null
  readonly losses: number | null
  readonly playerName: string | null
  readonly whip: number | null
  readonly wins: number | null
}

function normalizedText(value: string | null | undefined): string {
  return stripBasicTags(value ?? '').trim()
}

function numberFromText(value: string | null | undefined): number | null {
  const text = normalizedText(value)
  if (text === '' || text === '-') {
    return null
  }

  const parsed = Number(text.replace(/,/g, ''))
  return Number.isFinite(parsed) ? parsed : null
}

function textFromClass(
  cells: RawKboPitcherRecordAnalysisResponse['rows'][number]['row'],
  className: StatClass
): string | null {
  return cells.find((cell) => cell.Class === className)?.Text ?? null
}

function playerNameFromCell(html: string | null | undefined): string | null {
  const htmlText = html ?? ''
  const nameMatch = htmlText.match(/<span class=['"]name['"]>([\s\S]*?)<\/span>/i)
  const name = normalizedText(nameMatch?.[1] ?? htmlText)
  return name === '' ? null : name
}

function winsLossesFromCell(html: string | null | undefined): Pick<RowStats, 'wins' | 'losses'> {
  const text = normalizedText(html)
  const match = text.match(/시즌\s*([0-9]+)승\s*([0-9]+)패/)
  return {
    wins: match?.[1] == null ? null : Number(match[1]),
    losses: match?.[2] == null ? null : Number(match[2])
  }
}

function statsForRow(
  row: RawKboPitcherRecordAnalysisResponse['rows'][number],
  side: ProbablePitcherSide
): RowStats {
  const pitcherCell = row.row.find((cell) => cell.Class === 'pitcher')?.Text
  const suffix = side === 'away' ? 'T' : 'B'
  const { wins, losses } = winsLossesFromCell(pitcherCell)

  return {
    era: numberFromText(textFromClass(row.row, `td_era_${suffix}`)),
    games: numberFromText(textFromClass(row.row, `td_game_${suffix}`)),
    losses,
    playerName: playerNameFromCell(pitcherCell),
    whip: numberFromText(textFromClass(row.row, `td_whip_${suffix}`)),
    wins
  }
}

function starterForSide(starters: readonly ProbablePitcherStarter[], side: ProbablePitcherSide): ProbablePitcherStarter | null {
  return starters.find((starter) => starter.side === side) ?? null
}

function entryFromStats(starter: ProbablePitcherStarter, stats: RowStats): PitchingLeaderEntry {
  return {
    playerId: starter.playerId,
    playerName: stats.playerName ?? starter.playerName,
    teamId: starter.teamId,
    teamName: starter.teamName,
    rank: null,
    games: stats.games,
    completeGames: null,
    shutouts: null,
    wins: stats.wins,
    losses: stats.losses,
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
    era: stats.era,
    whip: stats.whip
  }
}

export function mapProbablePitcherRecordAnalysis(input: ProbablePitcherRecordAnalysisInput): PitchingLeaderEntry[] {
  return input.response.rows.flatMap((row, index) => {
    const side: ProbablePitcherSide = index === 0 ? 'away' : 'home'
    const starter = starterForSide(input.starters, side)
    if (starter == null) {
      return []
    }

    return [entryFromStats(starter, statsForRow(row, side))]
  })
}
