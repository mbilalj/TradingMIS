import { useState } from 'react'
import { compact, fmt } from '../lib/format'

/** Dependency-free column chart with hover read-out, used for the dashboard sales trend. */
export default function BarChart({ data, height = 190 }: { data: { label: string; value: number }[]; height?: number }) {
  const [hover, setHover] = useState<number | null>(null)
  const max = Math.max(1, ...data.map((d) => d.value))
  const W = 640
  const pad = { l: 8, r: 8, t: 14, b: 26 }
  const bw = (W - pad.l - pad.r) / Math.max(1, data.length)
  const ih = height - pad.t - pad.b

  return (
    <div style={{ position: 'relative' }}>
      <svg viewBox={`0 0 ${W} ${height}`} width="100%" role="img" aria-label="Sales trend">
        <defs>
          <linearGradient id="bar" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#4f7bff" />
            <stop offset="100%" stopColor="#2b50d9" />
          </linearGradient>
        </defs>
        {[0.25, 0.5, 0.75, 1].map((t) => (
          <line key={t} x1={pad.l} x2={W - pad.r} y1={pad.t + ih * (1 - t)} y2={pad.t + ih * (1 - t)} stroke="#e8ecf4" strokeDasharray="3 4" />
        ))}
        <line x1={pad.l} x2={W - pad.r} y1={pad.t + ih} y2={pad.t + ih} stroke="#cfd6e3" />
        {data.map((d, i) => {
          const h = d.value > 0 ? Math.max(3, (d.value / max) * ih) : 0
          const x = pad.l + i * bw + bw * 0.18
          return (
            <g key={d.label} onMouseEnter={() => setHover(i)} onMouseLeave={() => setHover(null)}>
              <rect x={pad.l + i * bw} y={pad.t} width={bw} height={ih + 20} fill="transparent" />
              <rect x={x} y={pad.t + ih - h} width={bw * 0.64} height={h} rx={4} fill={hover === i ? '#1d3fae' : 'url(#bar)'} opacity={hover == null || hover === i ? 1 : 0.55} />
              {(i % 2 === 0 || data.length < 9) && (
                <text x={pad.l + i * bw + bw / 2} y={height - 8} textAnchor="middle" fontSize="10.5" fill="#7b8798">{d.label}</text>
              )}
            </g>
          )
        })}
      </svg>
      {hover != null && (
        <div style={{ position: 'absolute', top: 0, right: 0, background: '#0f172a', color: '#fff', borderRadius: 9, padding: '6px 11px', fontSize: 12.5 }}>
          <b>{data[hover].label}</b> · Rs {fmt(data[hover].value)}
        </div>
      )}
      <div className="muted" style={{ fontSize: 11.5, marginTop: 2 }}>Peak day: Rs {compact(max)}</div>
    </div>
  )
}
