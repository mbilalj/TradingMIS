import { useEffect, useMemo, useRef, useState } from 'react'
import type { ProductRow } from '../api/types'
import { money, qty } from '../lib/format'
import { Badge, Modal } from './ui'

/**
 * Full-window product list opened from any product picker (F4 or the list button).
 * Enter / double-click picks the highlighted product for the current line; tick several and
 * "Add selected" to put them all on the document at once.
 */
export default function ProductBrowser({ rows, mode, current, onPick, onPickMany, onClose }: {
  rows: ProductRow[]
  /** 'sale' shows selling prices and hides nothing; 'purchase' shows last cost. */
  mode: 'sale' | 'purchase'
  current?: string
  onPick: (productId: string) => void
  onPickMany?: (productIds: string[]) => void
  onClose: () => void
}) {
  const [q, setQ] = useState('')
  const [category, setCategory] = useState('')
  const [inStock, setInStock] = useState(false)
  const [active, setActive] = useState(0)
  const [ticked, setTicked] = useState<string[]>([])
  const body = useRef<HTMLTableSectionElement>(null)

  const categories = useMemo(() => [...new Set(rows.map((r) => r.product.category).filter(Boolean) as string[])].sort(), [rows])
  const shown = useMemo(() => {
    const words = q.trim().toLowerCase().split(/\s+/).filter(Boolean)
    return rows.filter((r) => {
      const p = r.product
      if (!p.active || (category && p.category !== category) || (inStock && r.onHand <= 0)) return false
      const hay = `${p.sku} ${p.name} ${p.brand ?? ''} ${p.category ?? ''}`.toLowerCase()
      return words.every((w) => hay.includes(w))
    })
  }, [rows, q, category, inStock])

  useEffect(() => { setActive(0) }, [q, category, inStock])
  useEffect(() => { body.current?.querySelector<HTMLElement>('tr[data-active="true"]')?.scrollIntoView({ block: 'nearest' }) }, [active])

  const toggle = (id: string) => setTicked((t) => (t.includes(id) ? t.filter((x) => x !== id) : [...t, id]))
  const pickOne = (id: string) => { onPick(id); onClose() }

  function onKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive((a) => Math.min(a + 1, shown.length - 1)) }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((a) => Math.max(a - 1, 0)) }
    else if (e.key === 'PageDown') { e.preventDefault(); setActive((a) => Math.min(a + 12, shown.length - 1)) }
    else if (e.key === 'PageUp') { e.preventDefault(); setActive((a) => Math.max(a - 12, 0)) }
    else if (e.key === 'Enter' && !e.ctrlKey && shown[active]) {
      e.preventDefault()
      if (e.shiftKey && onPickMany) toggle(String(shown[active].product.id))
      else pickOne(String(shown[active].product.id))
    }
  }

  return (
    <Modal full title={`All products · ${shown.length} of ${rows.filter((r) => r.product.active).length}`} onClose={onClose}
      footer={<>
        <span className="muted" style={{ marginRight: 'auto', fontSize: 12.5 }}>↑↓ move · Enter picks for this line{onPickMany && ' · Shift+Enter ticks'} · Esc closes</span>
        <button className="btn btn-ghost" onClick={onClose}>Close</button>
        {onPickMany && <button className="btn btn-primary" disabled={!ticked.length} onClick={() => { onPickMany(ticked); onClose() }}>Add {ticked.length || ''} selected</button>}
      </>}>
      <div className="browse-tools">
        <div className="search-box" style={{ width: 'min(420px, 100%)' }}>
          <input className="input" style={{ paddingLeft: 12 }} placeholder="Search code, name, brand or category…" value={q} autoFocus
            onChange={(e) => setQ(e.target.value)} onKeyDown={onKeyDown} />
        </div>
        <select className="select" style={{ width: 200 }} value={category} onChange={(e) => setCategory(e.target.value)}>
          <option value="">All categories</option>
          {categories.map((c) => <option key={c} value={c}>{c}</option>)}
        </select>
        <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
          <input type="checkbox" checked={inStock} onChange={(e) => setInStock(e.target.checked)} /> In stock only
        </label>
      </div>
      <div className="browse-table">
        <table className="tbl compact">
          <thead><tr>
            {onPickMany && <th style={{ width: 36 }} />}
            <th>Code</th><th>Product</th><th>Brand</th><th>Category</th><th>Unit</th><th className="n">On hand</th>
            {mode === 'sale' ? <><th className="n">Retail</th><th className="n">Wholesale</th></> : <th className="n">Last cost</th>}
          </tr></thead>
          <tbody ref={body}>
            {shown.length === 0 && <tr><td colSpan={9}><div className="empty">No product matches.</div></td></tr>}
            {shown.map((r, i) => {
              const p = r.product
              const id = String(p.id)
              return (
                <tr key={id} data-active={i === active} className={`browse-row ${i === active ? 'selected' : ''}`}
                  onMouseEnter={() => setActive(i)} onClick={() => (onPickMany ? toggle(id) : pickOne(id))} onDoubleClick={() => pickOne(id)}>
                  {onPickMany && <td onClick={(e) => e.stopPropagation()}><input type="checkbox" checked={ticked.includes(id)} onChange={() => toggle(id)} /></td>}
                  <td><b>{p.sku}</b>{id === current && <> <Badge tone="primary">this line</Badge></>}</td>
                  <td>{p.name}</td>
                  <td className="text-2">{p.brand ?? '—'}</td>
                  <td className="text-2">{p.category ?? '—'}</td>
                  <td>{p.baseUnit.name}{p.units.length > 0 && <span className="muted"> +{p.units.map((u) => u.unit.name).join(', ')}</span>}</td>
                  <td className={`n ${r.onHand <= 0 ? 'neg' : r.lowStock ? 'warn-text' : ''}`}>{r.onHand > 0 ? qty(r.onHand) : 'out'}</td>
                  {mode === 'sale'
                    ? <><td className="n">{money(p.retailPrice || p.sellingPrice)}</td><td className="n">{money(p.wholesalePrice || p.sellingPrice)}</td></>
                    : <td className="n">{r.lastCost ? money(r.lastCost) : '—'}</td>}
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
      {onPickMany && <div className="muted" style={{ fontSize: 12, marginTop: 8 }}>Click rows to tick several, then <b>Add selected</b>. Double-click (or Enter) puts one product on the current line.</div>}
    </Modal>
  )
}
