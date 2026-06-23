import { stripBasicTags } from './sourceCollectionUtils.js'

export interface TopFiveCategory {
  title: string
  leaders: Array<{
    rank: number
    playerId: string
    playerName: string
    teamName: string
    value: string
  }>
}

export function parseTopFiveCategories(html: string): TopFiveCategory[] {
  const categories: TopFiveCategory[] = []
  const recordBlocks = [...html.matchAll(/<div class="record(?:\s+mr15)?">([\s\S]*?)(?=<div class="record(?:\s+mr15)?">|<div class="record_list|<div class="record_tit02|<\/form>|$)/g)]

  for (const blockMatch of recordBlocks) {
    const block = blockMatch[1]
    const title = stripBasicTags(block.match(/<span class="title">([\s\S]*?)<\/span>/i)?.[1] ?? '')
    if (!title) {
      continue
    }

    const leaders = [...block.matchAll(/<li>\s*<span class=['"]rank([0-9]+) name['"]><a href="[^"]*playerId=([0-9A-Za-z_-]+)[^"]*">([\s\S]*?)<\/a><\/span>\s*<span class="team">([\s\S]*?)<\/span>\s*<span class="rr">([\s\S]*?)<\/span>\s*<\/li>/gi)]
      .map((match) => ({
        rank: Number(match[1]),
        playerId: match[2],
        playerName: stripBasicTags(match[3]),
        teamName: stripBasicTags(match[4]),
        value: stripBasicTags(match[5])
      }))

    if (leaders.length > 0) {
      categories.push({ title, leaders })
    }
  }

  return categories
}
