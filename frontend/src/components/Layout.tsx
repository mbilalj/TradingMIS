import { useEffect, useRef, useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { canView } from '../auth/access'
import { Api } from '../api/resources'
import { useSettings } from '../api/hooks'
import type { SearchHit } from '../api/types'
import { fmtDate, today } from '../lib/format'
import { isTyping, modalOpen, useHotkeys } from '../lib/hotkeys'
import Icon, { type IconName } from './Icon'
import { BrandLockup, PoweredBy } from './Brand'
import { Kbd, Modal } from './ui'

const NAV: { group: string; items: { key: string; label: string; to: string; icon: IconName }[] }[] = [
  { group: 'Overview', items: [{ key: 'dash', label: 'Dashboard', to: '/', icon: 'dashboard' }] },
  {
    group: 'Inventory', items: [
      { key: 'products', label: 'Products', to: '/products', icon: 'box' },
      { key: 'receiving', label: 'Stock receiving', to: '/receiving', icon: 'truck' },
      { key: 'stock', label: 'Stock & batches', to: '/stock', icon: 'layers' },
    ],
  },
  {
    group: 'Sales', items: [
      { key: 'sales', label: 'Sales & invoices', to: '/sales', icon: 'cart' },
      { key: 'returns', label: 'Sales returns', to: '/returns', icon: 'undo' },
      { key: 'customers', label: 'Customers', to: '/customers', icon: 'users' },
    ],
  },
  {
    group: 'Payments', items: [
      { key: 'receipts', label: 'Receivables', to: '/receivables', icon: 'inbox' },
      { key: 'receipts', label: 'Customer payments', to: '/receipts', icon: 'coins' },
      { key: 'suppliers', label: 'Suppliers', to: '/suppliers', icon: 'building' },
      { key: 'supplierpay', label: 'Supplier payments', to: '/supplier-payments', icon: 'card' },
      { key: 'expenses', label: 'Expenses', to: '/expenses', icon: 'receipt' },
      { key: 'cash', label: 'Cash & bank', to: '/cash', icon: 'wallet' },
    ],
  },
  {
    group: 'Insights', items: [
      { key: 'finreports', label: 'Profit & Loss', to: '/reports/profit-loss', icon: 'scale' },
      { key: 'reports', label: 'Reports', to: '/reports', icon: 'chart' },
    ],
  },
  { group: 'Admin', items: [{ key: 'settings', label: 'Settings', to: '/settings', icon: 'settings' }] },
]

/** "g" then a letter jumps to a screen, e.g. g s = Sales, g n = New sale. */
const CHORDS: Record<string, { to: string; key: string; label: string }> = {
  d: { to: '/', key: 'dash', label: 'Dashboard' },
  p: { to: '/products', key: 'products', label: 'Products' },
  r: { to: '/receiving', key: 'receiving', label: 'Stock receiving (containers)' },
  t: { to: '/stock', key: 'stock', label: 'Stock & batches' },
  s: { to: '/sales', key: 'sales', label: 'Sales & invoices' },
  n: { to: '/sales/new', key: 'sales', label: 'New sale' },
  u: { to: '/returns', key: 'returns', label: 'Sales returns' },
  c: { to: '/customers', key: 'customers', label: 'Customers' },
  y: { to: '/receivables', key: 'receipts', label: 'Receivables' },
  m: { to: '/receipts', key: 'receipts', label: 'Customer payments' },
  v: { to: '/suppliers', key: 'suppliers', label: 'Suppliers' },
  a: { to: '/supplier-payments', key: 'supplierpay', label: 'Supplier payments' },
  e: { to: '/expenses', key: 'expenses', label: 'Expenses' },
  b: { to: '/cash', key: 'cash', label: 'Cash & bank' },
  f: { to: '/reports/profit-loss', key: 'finreports', label: 'Profit & Loss' },
  o: { to: '/reports', key: 'reports', label: 'Reports' },
  g: { to: '/settings', key: 'settings', label: 'Settings' },
}

const SHORTCUT_SECTIONS: { title: string; rows: [string, string][] }[] = [
  { title: 'Anywhere', rows: [['Ctrl+K', 'Search everything'], ['?  or  F1', 'This help'], ['G then a letter', 'Go to a screen (list at right)']] },
  { title: 'Lists', rows: [['Alt+N', 'New record (on every list screen)'], ['↑ / ↓', 'Move the highlighted row'], ['Enter', 'Open the highlighted row'], ['Alt+E', 'Edit the highlighted row'], ['Delete', 'Delete the highlighted row (where allowed)'], ['/', 'Filter the list']] },
  { title: 'Forms & dialogs', rows: [['Ctrl+S  or  Ctrl+Enter', 'Save'], ['Esc', 'Close the dialog'], ['Tab / Shift+Tab', 'Next / previous field']] },
  { title: 'Sale & receiving forms', rows: [['Type in Product', 'Type-ahead; ↑↓ then Enter picks it'], ['Ctrl+S', 'Save'], ['Ctrl+P', 'Save & print (sales)'], ['Alt+A  or  F2', 'Add a line'], ['Alt+Delete', 'Remove the current line'], ['Enter in Qty / Rate', 'Jump to the next field']] },
  { title: 'Cash & bank', rows: [['Alt+R', 'Money in'], ['Alt+P', 'Money out'], ['Alt+T', 'Transfer']] },
  { title: 'Customer & supplier accounts', rows: [['Alt+E', 'Edit'], ['Alt+P', 'Receive / make payment'], ['Alt+A', 'Balance adjustment']] },
]

export function ShortcutsHelp({ onClose, role }: { onClose: () => void; role?: string }) {
  return (
    <Modal wide title="Keyboard shortcuts" onClose={onClose}>
      <div className="help-grid">
        <div>
          {SHORTCUT_SECTIONS.map((s) => (
            <div key={s.title} style={{ marginBottom: 16 }}>
              <div className="card-title" style={{ marginBottom: 6 }}>{s.title}</div>
              {s.rows.map(([k, d]) => <div key={k + d} className="help-row"><span className="text-2">{d}</span><Kbd>{k}</Kbd></div>)}
            </div>
          ))}
        </div>
        <div>
          <div className="card-title" style={{ marginBottom: 6 }}>Go to (press G, then…)</div>
          {Object.entries(CHORDS).filter(([, c]) => canView(role as never, c.key)).map(([k, c]) => (
            <div key={k} className="help-row"><span className="text-2">{c.label}</span><Kbd>G {k.toUpperCase()}</Kbd></div>
          ))}
        </div>
      </div>
    </Modal>
  )
}

function hitRoute(h: SearchHit): string {
  switch (h.type) {
    case 'Product': return `/products?q=${encodeURIComponent(h.label)}`
    case 'Batch':
    case 'Shipment': return `/shipments/${h.id}`
    case 'Customer': return `/customers/${h.id}`
    case 'Supplier': return `/suppliers/${h.id}`
    case 'Invoice': return `/sales/${h.id}`
    default: return '/'
  }
}

function GlobalSearch() {
  const navigate = useNavigate()
  const [q, setQ] = useState('')
  const [hits, setHits] = useState<SearchHit[]>([])
  const [open, setOpen] = useState(false)
  const box = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (q.trim().length < 2) { setHits([]); return }
    const t = setTimeout(() => { Api.search(q.trim()).then(setHits).catch(() => setHits([])) }, 220)
    return () => clearTimeout(t)
  }, [q])

  useEffect(() => {
    const onDoc = (e: MouseEvent) => { if (box.current && !box.current.contains(e.target as Node)) setOpen(false) }
    document.addEventListener('mousedown', onDoc)
    return () => document.removeEventListener('mousedown', onDoc)
  }, [])

  return (
    <div className="search-box" ref={box}>
      <Icon name="search" size={17} />
      <input id="global-search" className="input" placeholder="Search product, container, customer, supplier or invoice…  (Ctrl+K)" value={q}
        onChange={(e) => { setQ(e.target.value); setOpen(true) }} onFocus={() => setOpen(true)} />
      {open && q.trim().length >= 2 && (
        <div className="search-pop">
          {hits.length === 0 && <div className="empty" style={{ padding: 18 }}>No matches for “{q}”.</div>}
          {hits.map((h, i) => (
            <div key={h.type + h.id + i} className="search-hit" onClick={() => { setOpen(false); setQ(''); navigate(hitRoute(h)) }}>
              <span className="badge primary" style={{ minWidth: 68, justifyContent: 'center' }}>{h.type}</span>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontWeight: 650 }}>{h.label}</div>
                <div className="muted" style={{ fontSize: 12, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{h.sub}</div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default function Layout() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const settings = useSettings()
  const initials = (user?.fullName ?? '?').split(' ').map((p) => p[0]).slice(0, 2).join('')

  const [help, setHelp] = useState(false)

  useEffect(() => { window.scrollTo(0, 0) }, [location.pathname])
  useHotkeys({
    '?': () => setHelp(true), 'shift+?': () => setHelp(true), f1: () => setHelp(true),
    'ctrl+k': () => document.getElementById('global-search')?.focus(),
  })
  useEffect(() => {
    let armed = 0
    const onKey = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.altKey || e.metaKey || e.isComposing || isTyping(e.target) || modalOpen()) return
      const k = e.key.toLowerCase()
      if (armed && Date.now() - armed < 1500) {
        armed = 0
        const c = CHORDS[k]
        if (c && canView(user?.role, c.key)) { e.preventDefault(); navigate(c.to) }
        return
      }
      if (k === 'g') armed = Date.now()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [navigate, user?.role])

  return (
    <div className="shell">
      <aside className="sidebar no-print">
        <div className="brand" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 8 }}>
          <BrandLockup size={36} dark />
          {settings.data?.['business.name'] && <div className="brand-sub">{settings.data['business.name']}</div>}
        </div>

        {NAV.map((g) => {
          const items = g.items.filter((it) => canView(user?.role, it.key))
          if (!items.length) return null
          return (
            <div key={g.group} className="nav-group">
              <div className="nav-title">{g.group}</div>
              {items.map((it) => (
                <NavLink key={it.to} to={it.to} end={it.to === '/' || it.to === '/reports'} className={({ isActive }) => 'nav-link' + (isActive ? ' active' : '')}>
                  <Icon name={it.icon} size={18} />
                  {it.label}
                </NavLink>
              ))}
            </div>
          )
        })}

        <div className="side-foot">
          <button className="nav-link" style={{ width: '100%', background: 'none', border: 0, cursor: 'pointer', font: 'inherit' }} onClick={() => setHelp(true)}>
            <Icon name="info" size={18} /> Shortcuts<Kbd>?</Kbd>
          </button>
          <button className="nav-link" style={{ width: '100%', background: 'none', border: 0, cursor: 'pointer', font: 'inherit' }}
            onClick={() => { logout(); navigate('/login') }}>
            <Icon name="logout" size={18} /> Sign out
          </button>
          <div style={{ padding: '14px 10px 0', marginTop: 10, borderTop: '1px solid rgba(255,255,255,.07)' }}><PoweredBy dark size={11} /></div>
        </div>
      </aside>

      <div className="main">
        <header className="topbar no-print">
          <GlobalSearch />
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 16 }}>
            <div className="muted" style={{ fontSize: 12.5, display: 'flex', alignItems: 'center', gap: 6 }}>
              <Icon name="clock" size={15} /> {fmtDate(today())}
            </div>
            <div className="user-chip">
              <div className="avatar">{initials}</div>
              <div style={{ lineHeight: 1.2, paddingRight: 8 }}>
                <div style={{ fontSize: 13, fontWeight: 650 }}>{user?.fullName}</div>
                <div className="muted" style={{ fontSize: 11 }}>{user?.role.replace('_', ' ').toLowerCase()}</div>
              </div>
            </div>
          </div>
        </header>
        <div className="content">
          <Outlet />
        </div>
        {help && <ShortcutsHelp role={user?.role} onClose={() => setHelp(false)} />}
      </div>
    </div>
  )
}
