import { useId } from 'react'

/**
 * Brand marks. Portside is a TrenovaSys product: its mark blends Portside blue with the TrenovaSys
 * cyan → teal → deep green, navy for type, and a gold accent for money.
 */
const BRAND = { blue: '#2453d6', sky: '#1e8fd0', cyan: '#19b6cf', teal: '#0f9e86', green: '#0b5e50', navy: '#0f172a', slate: '#475569', gold: '#f5b524' }

/* Vector trace of the TrenovaSys "T" (48×48), so the parent mark renders crisply on any background. */
const T_BODY = 'M2 6.5 46 2l-4 9.5-6.5.8L27.6 43a3.6 3.6 0 0 1-3.4 2.8h-1.7a3.6 3.6 0 0 1-3.2-2L10.3 28.8V12.8Z'
const T_FOLD = 'M2 6.5 10.3 12.8V8.6Z'

function TrenovaGlyph({ gid, person = true }: { gid: string; person?: boolean }) {
  return (
    <>
      <defs>
        <linearGradient id={gid} x1="0" y1="0" x2=".55" y2="1">
          <stop offset="0" stopColor={BRAND.cyan} />
          <stop offset=".5" stopColor={BRAND.teal} />
          <stop offset="1" stopColor={BRAND.green} />
        </linearGradient>
      </defs>
      <path d={T_BODY} fill={`url(#${gid})`} />
      <path d={T_FOLD} fill="#000" opacity=".16" />
      {person && (
        <g fill="none" stroke="#fff" strokeLinecap="round">
          <circle cx="25" cy="17.4" r="6.4" strokeWidth="1.1" strokeDasharray="1.6 1.5" />
          <circle cx="25" cy="15" r="1.5" fill="#fff" stroke="none" />
          <path d="M22.5 18.9c.8 1.5 1.5 1.9 2.5 1.9s1.7-.4 2.5-1.9" strokeWidth="1.4" />
          <path d="M17.8 37.5c3-3.6 5.8-8.2 7.2-14.4" strokeWidth="1.5" />
        </g>
      )}
    </>
  )
}

/** The TrenovaSys organisation mark on its own. */
export function TrenovaMark({ size = 24 }: { size?: number }) {
  const id = useId().replace(/:/g, '')
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" role="img" aria-label="TrenovaSys" style={{ flexShrink: 0, display: 'block' }}>
      <TrenovaGlyph gid={`tg${id}`} person={size >= 18} />
    </svg>
  )
}

/**
 * Portside mark — the whole business in one tile:
 * a shipping container at the quay carrying wholesale cartons (left), the trader (centre),
 * a retail shopping bag (right) and a rupee coin for the money that flows through it.
 */
export function PortsideMark({ size = 38 }: { size?: number }) {
  const id = useId().replace(/:/g, '')
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" role="img" aria-label="Portside" style={{ flexShrink: 0, display: 'block' }}>
      <PortsideGlyph id={id} />
    </svg>
  )
}

/* The T with its arm drawn long (72×48) so the Portside tile fits in the right angle under it. */
const T_WIDE = 'M2 6.5 72 0 68.5 12.3H35.5L27.6 43a3.6 3.6 0 0 1-3.4 2.8h-1.7a3.6 3.6 0 0 1-3.2-2L10.3 28.8V12.8Z'

/**
 * The merged application mark: the TrenovaSys T, with the Portside tile standing in the corner between
 * its stem and arm, filling the T's right side down to its base. `size` is the height; the mark is 72∶48 wide.
 */
export function PortsideTrenovaMark({ size = 40 }: { size?: number }) {
  const id = useId().replace(/:/g, '')
  return (
    <svg width={size * 72 / 48} height={size} viewBox="0 0 72 48" role="img" aria-label="Portside by TrenovaSys" style={{ flexShrink: 0, display: 'block' }}>
      <defs>
        <linearGradient id={`mt${id}`} x1="0" y1="0" x2=".45" y2="1">
          <stop offset="0" stopColor={BRAND.cyan} />
          <stop offset=".5" stopColor={BRAND.teal} />
          <stop offset="1" stopColor={BRAND.green} />
        </linearGradient>
      </defs>
      <path d={T_WIDE} fill={`url(#mt${id})`} />
      <path d={T_FOLD} fill="#000" opacity=".16" />
      {size >= 20 && (
        <g fill="none" stroke="#fff" strokeLinecap="round">
          <circle cx="23.5" cy="20" r="6.4" strokeWidth="1.1" strokeDasharray="1.6 1.5" />
          <circle cx="23.5" cy="17.6" r="1.5" fill="#fff" stroke="none" />
          <path d="M21 21.5c.8 1.5 1.5 1.9 2.5 1.9s1.7-.4 2.5-1.9" strokeWidth="1.4" />
          <path d="M17.8 38.5c2.6-3.2 4.6-6.8 5.7-11.4" strokeWidth="1.5" />
        </g>
      )}
      <svg x="36.5" y="14" width="32" height="32" viewBox="0 0 48 48"><PortsideGlyph id={`m${id}`} /></svg>
    </svg>
  )
}

function PortsideGlyph({ id }: { id: string }) {
  return (
    <>
      <defs>
        <linearGradient id={`pg${id}`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor={BRAND.blue} />
          <stop offset=".5" stopColor={BRAND.sky} />
          <stop offset="1" stopColor={BRAND.teal} />
        </linearGradient>
        <linearGradient id={`pc${id}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#ffd45e" />
          <stop offset="1" stopColor={BRAND.gold} />
        </linearGradient>
      </defs>
      <rect width="48" height="48" rx="12" fill={`url(#pg${id})`} />

      {/* wholesale: a stack of cartons */}
      <rect x="6.5" y="20.5" width="7" height="6.5" rx="1" fill="#fff" />
      <rect x="14.2" y="20.5" width="7" height="6.5" rx="1" fill="#fff" />
      <rect x="10.35" y="13.4" width="7" height="6.5" rx="1" fill="#fff" />
      <path d="M10 20.5v2.4M17.7 20.5v2.4M13.85 13.4v2.4" stroke={BRAND.blue} strokeWidth="1.2" strokeLinecap="round" />

      {/* the trader, in a tie */}
      <circle cx="28.4" cy="12.6" r="3.6" fill="#fff" />
      <path d="M22.9 27c0-5.2 2.4-8.6 5.5-8.6s5.5 3.4 5.5 8.6Z" fill="#fff" />
      <path d="m28.4 18.9-1.1 1.7.9 4.6h.4l.9-4.6Z" fill={BRAND.blue} />

      {/* retail: a price tag */}
      <g transform="rotate(-38 38.6 23.4)">
        <path d="M33.6 23.4 37 19.6h6.4v7.6H37Z" fill="#fff" />
        <circle cx="37.4" cy="23.4" r="1.15" fill={BRAND.sky} />
      </g>

      {/* money: a rupee coin */}
      <circle cx="39.6" cy="9.4" r="5.4" fill={`url(#pc${id})`} stroke="#fff" strokeWidth="1.1" />
      <text x="39.6" y="11.35" textAnchor="middle" fontSize="5.4" fontWeight="800" fontFamily="Inter, Segoe UI, Arial, sans-serif" fill="#7a4b00">Rs</text>

      {/* the container everything stands on */}
      <rect x="5" y="28" width="38" height="10" rx="1.8" fill="#fff" />
      <path d="M11 30.6v4.8M16 30.6v4.8M21 30.6v4.8M26 30.6v4.8M31 30.6v4.8M36 30.6v4.8" stroke={BRAND.sky} strokeWidth="1.3" strokeLinecap="round" />

      {/* the water at the port */}
      <path d="M6 42.6c2.3-2.2 4.6-2.2 6.9 0s4.6 2.2 6.9 0 4.6-2.2 6.9 0 4.6 2.2 6.9 0 4.6-2.2 6.9 0" fill="none" stroke="#fff" strokeWidth="2.2" strokeLinecap="round" opacity=".85" />
    </>
  )
}

/** The Portside punch line, set under the name in every lockup. */
export const PORTSIDE_TAGLINE = 'Every container. Every rupee.'

/** The application lockup: the merged TrenovaSys + Portside mark, the Portside name and its punch line. */
export function BrandLockup({ size = 38, dark }: { size?: number; dark?: boolean }) {
  return (
    <div className="brand-lockup" style={{ display: 'flex', alignItems: 'center', gap: size * 0.24, minWidth: 0 }}>
      <PortsideTrenovaMark size={size} />
      <div style={{ lineHeight: 1.1, minWidth: 0 }}>
        <div style={{ fontWeight: 800, fontSize: size * 0.5, letterSpacing: '-0.02em', color: dark ? '#fff' : BRAND.blue }}>
          Port<span style={{ color: dark ? '#3fd0c0' : BRAND.teal }}>side</span>
        </div>
        <div style={{ fontSize: Math.max(9.5, size * 0.27), fontWeight: 600, color: dark ? '#8fb3c9' : BRAND.slate, marginTop: size * 0.06, whiteSpace: 'nowrap' }}>
          {PORTSIDE_TAGLINE}
        </div>
      </div>
    </div>
  )
}

/*
 * The official TrenovaSys logo artwork (public/brand/trenovasys.jpg, 920×240). It is shown cropped to the
 * mark + name + tagline so it sits tidily inline; on dark backgrounds it goes on a light chip.
 */
const TRENOVA_SRC = '/brand/trenovasys.jpg'
const CROP = { x: 30, y: 34, w: 625, h: 188 }

export function TrenovaLogo({ height = 22, dark }: { height?: number; dark?: boolean }) {
  const s = height / CROP.h
  const img = (
    <span style={{ display: 'block', width: CROP.w * s, height, overflow: 'hidden', flexShrink: 0 }}>
      <img src={TRENOVA_SRC} alt="TrenovaSys — Built for People · Powered by Systems" draggable={false}
        style={{ display: 'block', width: 920 * s, height: 240 * s, maxWidth: 'none', marginLeft: -CROP.x * s, marginTop: -CROP.y * s, filter: dark ? undefined : 'brightness(1.035)' }} />
    </span>
  )
  if (!dark) return img
  return <span style={{ display: 'inline-flex', padding: `${height * 0.14}px ${height * 0.3}px`, borderRadius: 6, background: '#f7f7f7' }}>{img}</span>
}

/** "Powered by TrenovaSys" credit, used in the app chrome and on every printed document. */
export function PoweredBy({ dark, size = 12, center }: { dark?: boolean; size?: number; center?: boolean }) {
  return (
    <div className="powered-by" style={{ display: 'flex', alignItems: 'center', justifyContent: center ? 'center' : 'flex-start', gap: 8, fontSize: size, color: dark ? '#7f93ad' : BRAND.slate, whiteSpace: 'nowrap' }}>
      <span>Powered by</span>
      <TrenovaLogo height={size * 2.3} dark={dark} />
    </div>
  )
}

/** Footer printed at the bottom of invoices and reports. */
export function PrintCredit() {
  return (
    <div className="print-credit" style={{ marginTop: 22, paddingTop: 10, borderTop: '1px solid var(--line)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
      <BrandLockup size={22} />
      <PoweredBy size={10.5} />
    </div>
  )
}
