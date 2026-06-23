import { mkdir, writeFile } from 'node:fs/promises'
import path from 'node:path'

import { parseTopFiveCategories } from '../src/records/leagueRecordExtractors.js'
import { fetchTextWithTimeout } from '../src/records/sourceCollectionUtils.js'

function readArg(name: string, fallback?: string): string | undefined {
  const prefix = `--${name}`
  const args = process.argv.slice(2)

  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === prefix) {
      return args[i + 1] ?? fallback
    }
  }

  return fallback
}

function timestampForFile(date = new Date()): string {
  return date.toISOString().replaceAll(':', '-').replaceAll('.', '-')
}

async function writeJson(filePath: string, value: unknown) {
  await mkdir(path.dirname(filePath), { recursive: true })
  await writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8')
}

async function fetchCrowdTeam(year: string) {
  const body = new URLSearchParams({
    leagueId: '1',
    seriesId: '0',
    gameMonth: year
  })

  const response = await fetchTextWithTimeout('https://www.koreabaseball.com/ws/Record.asmx/GetCrowdTeam', {
    method: 'POST',
    headers: {
      'User-Agent': 'Mozilla/5.0',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest',
      Referer: 'https://www.koreabaseball.com/Record/Crowd/GraphTeam.aspx'
    },
    body
  })

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw new Error(`crowd team endpoint returned HTTP ${response.statusCode}`)
  }

  return {
    ...response,
    parsed: JSON.parse(response.body) as unknown
  }
}

async function main() {
  const runId = readArg('run-id', timestampForFile())!
  const year = readArg('year', '2026')!
  const outDir = readArg('out-dir', path.resolve('artifacts', 'league-record-data', runId))!

  const top5 = await fetchTextWithTimeout('https://www.koreabaseball.com/Record/Ranking/Top5.aspx', {
    headers: {
      'User-Agent': 'Mozilla/5.0',
      Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      Referer: 'https://www.koreabaseball.com/Record/Ranking/Top5.aspx'
    }
  })
  if (top5.statusCode < 200 || top5.statusCode >= 300) {
    throw new Error(`TOP5 page returned HTTP ${top5.statusCode}`)
  }

  const top5Categories = parseTopFiveCategories(top5.body)
  const crowdTeam = await fetchCrowdTeam(year)

  const top5File = path.join(outDir, 'top5.json')
  const crowdFile = path.join(outDir, 'crowd-team.json')
  const manifestFile = path.join(outDir, 'manifest.json')

  await writeJson(top5File, {
    source: 'kbo-official-top5',
    url: 'https://www.koreabaseball.com/Record/Ranking/Top5.aspx',
    fetchedAt: top5.fetchedAt,
    statusCode: top5.statusCode,
    categoryCount: top5Categories.length,
    categories: top5Categories
  })
  await writeJson(crowdFile, {
    source: 'kbo-official-crowd-team',
    url: 'https://www.koreabaseball.com/ws/Record.asmx/GetCrowdTeam',
    fetchedAt: crowdTeam.fetchedAt,
    statusCode: crowdTeam.statusCode,
    year,
    data: crowdTeam.parsed
  })

  const manifest = {
    runId,
    collectedAt: new Date().toISOString(),
    outDir: path.relative(process.cwd(), outDir),
    top5: {
      file: path.relative(process.cwd(), top5File),
      categoryCount: top5Categories.length,
      leaderCount: top5Categories.reduce((count, category) => count + category.leaders.length, 0)
    },
    crowdTeam: {
      file: path.relative(process.cwd(), crowdFile),
      year
    }
  }
  await writeJson(manifestFile, manifest)
  console.log(JSON.stringify(manifest, null, 2))
}

await main()
