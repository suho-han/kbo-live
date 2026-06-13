export class KboDateInputError extends Error {
  constructor(input: string) {
    super(`invalid date format: ${input}`)
    this.name = 'KboDateInputError'
  }
}

function dateInKorea(date: Date): string {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  }).formatToParts(date)
  const value = (type: string) => parts.find((part) => part.type === type)?.value

  return `${value('year')}-${value('month')}-${value('day')}`
}

export function normalizeInputDate(input?: string, now: Date = new Date()): string {
  if (!input) {
    return dateInKorea(now)
  }

  const digits = input.replace(/[^0-9]/g, '')
  if (digits.length !== 8) {
    throw new KboDateInputError(input)
  }

  return `${digits.slice(0, 4)}-${digits.slice(4, 6)}-${digits.slice(6, 8)}`
}

export function toKboDate(input?: string, now?: Date): string {
  return normalizeInputDate(input, now).replaceAll('-', '')
}
