import { isoDate } from '../lib/format'

export interface Range { from: string; to: string }

export function presetRange(kind: 'today' | 'week' | 'month' | 'lastMonth' | 'year'): Range {
  const now = new Date()
  const y = now.getFullYear()
  const m = now.getMonth()
  switch (kind) {
    case 'today': return { from: isoDate(now), to: isoDate(now) }
    case 'week': {
      const day = (now.getDay() + 6) % 7 // Monday = 0
      const start = new Date(y, m, now.getDate() - day)
      const end = new Date(y, m, now.getDate() - day + 6)
      return { from: isoDate(start), to: isoDate(end) }
    }
    case 'month': return { from: isoDate(new Date(y, m, 1)), to: isoDate(new Date(y, m + 1, 0)) }
    case 'lastMonth': return { from: isoDate(new Date(y, m - 1, 1)), to: isoDate(new Date(y, m, 0)) }
    case 'year': return { from: isoDate(new Date(y, 0, 1)), to: isoDate(new Date(y, 11, 31)) }
  }
}

const PRESETS: { key: 'today' | 'week' | 'month' | 'lastMonth' | 'year'; label: string }[] = [
  { key: 'today', label: 'Daily' },
  { key: 'week', label: 'Weekly' },
  { key: 'month', label: 'Monthly' },
  { key: 'lastMonth', label: 'Last month' },
  { key: 'year', label: 'Yearly' },
]

export default function DateRange({ value, onChange }: { value: Range; onChange: (r: Range) => void }) {
  const active = PRESETS.find((p) => {
    const r = presetRange(p.key)
    return r.from === value.from && r.to === value.to
  })?.key
  return (
    <div className="no-print" style={{ display: 'flex', gap: 10, alignItems: 'center', flexWrap: 'wrap' }}>
      <div className="seg">
        {PRESETS.map((p) => (
          <button key={p.key} type="button" className={active === p.key ? 'on' : ''} onClick={() => onChange(presetRange(p.key))}>{p.label}</button>
        ))}
      </div>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <input className="input input-sm" type="date" value={value.from} onChange={(e) => onChange({ ...value, from: e.target.value })} style={{ width: 150 }} aria-label="From date" />
        <span className="muted">to</span>
        <input className="input input-sm" type="date" value={value.to} onChange={(e) => onChange({ ...value, to: e.target.value })} style={{ width: 150 }} aria-label="To date" />
      </div>
    </div>
  )
}
