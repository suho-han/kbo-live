function decodeHtmlEntities(value: string): string {
  return value
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
}

function stripTags(value: string): string {
  return decodeHtmlEntities(value)
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]*>/g, '')
    .trim()
}

function isAtBatResultLine(line: string): boolean {
  if (/^[0-9]+(?:루)?주자\s/.test(line)) {
    return false
  }

  if (/^[0-9]+번타자\s/.test(line)) {
    return false
  }

  if (/^[0-9]+회[초말]\s/.test(line)) {
    return false
  }

  if (/^(?:ball|strike|out)$/i.test(line)) {
    return false
  }

  if (/^[0-9]-[0-9]\s+[0-9]out$/i.test(line)) {
    return false
  }

  return /^[가-힣A-Za-z][가-힣A-Za-z0-9 .·-]{0,24}\s*:\s*\S/.test(line)
}

export function parsePreviousAtBatResult(html: string): string | null {
  const lines = stripTags(html)
    .split(/\n+/)
    .map((line) => line.replace(/\s+/g, ' ').trim())
    .filter((line) => line.length > 0)

  for (let index = lines.length - 1; index >= 0; index -= 1) {
    const line = lines[index]
    if (line && isAtBatResultLine(line)) {
      return line
    }
  }

  return null
}
