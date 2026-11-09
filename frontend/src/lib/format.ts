const nf0 = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 })
const nf2 = new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
const nf4 = new Intl.NumberFormat('en-US', { maximumFractionDigits: 4 })

type N = number | string | null | undefined

function num(n: N): number | null {
  if (n == null || n === '') return null
  const v = typeof n === 'number' ? n : Number(n)
  return Number.isNaN(v) ? null : v
}

/** Whole rupees, thousands separated. */
export function fmt(n: N): string {
  const v = num(n)
  return v == null ? '—' : nf0.format(v)
}

/** Money with two decimals. */
export function money(n: N): string {
  const v = num(n)
  return v == null ? '—' : nf2.format(v)
}

/** Compact money for KPI cards: 1.25 M, 340 K. */
export function compact(n: N): string {
  const v = num(n)
  if (v == null) return '—'
  const a = Math.abs(v)
  if (a >= 1e7) return (v / 1e7).toFixed(2) + ' Cr'
  if (a >= 1e6) return (v / 1e6).toFixed(2) + ' M'
  if (a >= 1e5) return (v / 1e3).toFixed(0) + ' K'
  return nf0.format(v)
}

/** Quantities keep up to 4 decimals but drop trailing zeros. */
export function qty(n: N): string {
  const v = num(n)
  return v == null ? '—' : nf4.format(v)
}

export function pct(n: N): string {
  const v = num(n)
  return v == null ? '—' : (v * 100).toFixed(1) + '%'
}

export function toNum(n: N): number {
  return num(n) ?? 0
}

export function isoDate(d: Date): string {
  const z = new Date(d.getTime() - d.getTimezoneOffset() * 60000)
  return z.toISOString().slice(0, 10)
}

export function today(): string {
  return isoDate(new Date())
}

export function fmtDate(s: string | null | undefined): string {
  if (!s) return '—'
  const d = new Date(s + (s.length === 10 ? 'T00:00:00' : ''))
  if (Number.isNaN(d.getTime())) return s
  return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
}

export function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100
}

export function titleCase(s: string): string {
  return s.toLowerCase().replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}
