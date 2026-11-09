import { useEffect, useMemo, useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import { useAccounts, useCustomers, useProducts } from '../api/hooks'
import type { ProductRow, Sale, SaleType } from '../api/types'
import Icon from '../components/Icon'
import { useToast } from '../components/Toast'
import Combobox, { type ComboOption } from '../components/Combobox'
import ProductBrowser from '../components/ProductBrowser'
import { Banner, Card, Field, Kbd, Loading, PageHeader, Segmented } from '../components/ui'
import { enterTo, focusCell } from '../lib/focus'
import { useHotkeys } from '../lib/hotkeys'
import { money, qty, round2, today, toNum } from '../lib/format'
import { useAction } from '../lib/useAction'
import { METHODS } from './ExpenseModal'

interface Line { key: number; productId: string; unitId: string; batchId: string; qty: string; rate: string; rateTouched: boolean; discount: string; taxPct: string }
let seq = 1
const newLine = (taxPct = ''): Line => ({ key: seq++, productId: '', unitId: '', batchId: '', qty: '1', rate: '', rateTouched: false, discount: '', taxPct })

function factorOf(row: ProductRow | undefined, unitId: string): number {
  if (!row || !unitId || String(row.product.baseUnit.id) === unitId) return 1
  return Number(row.product.units.find((u) => String(u.unit.id) === unitId)?.factor ?? 1)
}

function defaultRate(row: ProductRow | undefined, type: SaleType, unitId: string): number {
  if (!row) return 0
  const p = row.product
  const base = (type === 'WHOLESALE' ? p.wholesalePrice : p.retailPrice) || p.sellingPrice || 0
  return round2(base * factorOf(row, unitId))
}

/** Choosing a product resets unit and container and fills in the default rate for the sale type. */
function productPatch(rows: ProductRow[], type: SaleType, productId: string): Partial<Line> {
  const r = rows.find((x) => String(x.product.id) === productId)
  return { productId, unitId: '', batchId: '', rate: r ? String(defaultRate(r, type, '')) : '', rateTouched: false }
}

/** batchId: '' = not chosen yet (defaults to the oldest container), 'ANY' = let stock span containers oldest-first. */
const ANY = 'ANY'

function LineRow({ line, index, rows, options, type, onChange, onRemove, removable, onQtyEnter, onBrowse }: {
  line: Line; index: number; rows: ProductRow[]; options: ComboOption[]; type: SaleType; onChange: (patch: Partial<Line>) => void; onRemove: () => void; removable: boolean; onQtyEnter: () => void; onBrowse: () => void
}) {
  const row = rows.find((r) => String(r.product.id) === line.productId)
  const batches = useQuery({ queryKey: ['product-batches', line.productId], queryFn: () => Api.productBatches(Number(line.productId)), enabled: !!line.productId })
  const unitId = line.unitId || (row ? String(row.product.baseUnit.id) : '')
  const factor = factorOf(row, unitId)
  const baseQty = toNum(line.qty) * factor
  const specific = !!line.batchId && line.batchId !== ANY
  const batch = batches.data?.find((b) => String(b.batchId) === line.batchId) ?? batches.data?.[0]
  const available = specific ? batch?.available ?? 0 : row?.onHand ?? 0

  // Selling is container-wise: as soon as the product is known, pre-select the oldest container that still has stock.
  const firstBatch = batches.data?.[0]
  useEffect(() => {
    if (line.productId && !line.batchId && firstBatch) onChange({ batchId: String(firstBatch.batchId) })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [line.productId, line.batchId, firstBatch?.batchId])
  const gross = round2(toNum(line.qty) * toNum(line.rate))
  const net = Math.max(0, gross - toNum(line.discount))
  const total = round2(net + net * toNum(line.taxPct) / 100)
  const cost = batch ? batch.unitCost * baseQty : 0
  const over = !!row && baseQty > available + 1e-9

  return (
    <tr>
      <td style={{ minWidth: 250 }}>
        <Combobox small options={options} value={line.productId} placeholder="Type code or name…  (F4 = all)" data={{ r: index, f: 'product' }}
          onChange={(v) => onChange(productPatch(rows, type, v))} onPicked={() => focusCell(index, 'qty')} onBrowse={onBrowse} />
        {row && <div className="muted" style={{ fontSize: 11.5, marginTop: 3 }}>
          {over ? <span className="neg">Only {qty(available / factor)} available{specific && <> in this container — pick “Any container” to span several</>}</span> : <>Available {qty(available / factor)}</>}
          {batch && toNum(line.rate) > 0 && baseQty > 0 && <> · cost Rs {money(cost)} · margin {(((net - cost) / (net || 1)) * 100).toFixed(1)}%</>}
        </div>}
      </td>
      <td style={{ width: 210 }}>
        <select className="select select-sm" value={line.batchId} onChange={(e) => onChange({ batchId: e.target.value })} disabled={!row} data-r={index} data-f="batch">
          {!line.batchId && <option value="">—</option>}
          {batches.data?.map((b) => <option key={b.batchId} value={b.batchId}>{b.containerNo ?? b.shipmentNo} · {qty(b.available)} left @ {money(b.unitCost)}</option>)}
          {(batches.data?.length ?? 0) > 1 && <option value={ANY}>Any container · oldest first</option>}
        </select>
      </td>
      <td style={{ width: 90 }}><input className="input input-sm num" type="number" min="0" value={line.qty} onChange={(e) => onChange({ qty: e.target.value })} data-r={index} data-f="qty" onKeyDown={enterTo(onQtyEnter)} /></td>
      <td style={{ width: 110 }}>
        <select className="select select-sm" value={unitId} disabled={!row} onChange={(e) => onChange({ unitId: e.target.value, rate: line.rateTouched ? line.rate : String(defaultRate(row, type, e.target.value)) })}>
          {row && [row.product.baseUnit, ...row.product.units.map((u) => u.unit)].map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
        </select>
      </td>
      <td style={{ width: 120 }}><input className="input input-sm num" type="number" min="0" value={line.rate} onChange={(e) => onChange({ rate: e.target.value, rateTouched: true })} data-r={index} data-f="rate" onKeyDown={enterTo(onQtyEnter)} /></td>
      <td style={{ width: 100 }}><input className="input input-sm num" type="number" min="0" value={line.discount} onChange={(e) => onChange({ discount: e.target.value })} placeholder="0" /></td>
      <td style={{ width: 70 }}><input className="input input-sm num" type="number" min="0" value={line.taxPct} onChange={(e) => onChange({ taxPct: e.target.value })} placeholder="0" /></td>
      <td className="n" style={{ width: 120, fontWeight: 700 }}>{money(total)}</td>
      <td style={{ width: 40 }}>{removable && <button className="btn btn-ghost btn-sm btn-icon" onClick={onRemove} aria-label="Remove line"><Icon name="trash" size={15} /></button>}</td>
    </tr>
  )
}

export default function NewSalePage() {
  const navigate = useNavigate()
  const toast = useToast()
  const products = useProducts()
  const customers = useCustomers()
  const accounts = useAccounts()
  const skuBox = useRef<HTMLInputElement>(null)

  const [type, setType] = useState<SaleType>('RETAIL')
  const [customerId, setCustomerId] = useState('')
  const [date, setDate] = useState(today())
  const [lines, setLines] = useState<Line[]>([newLine()])
  const [method, setMethod] = useState('CASH')
  const [accountId, setAccountId] = useState('')
  const [paid, setPaid] = useState('')
  const [paidTouched, setPaidTouched] = useState(false)
  const [remarks, setRemarks] = useState('')
  const [sku, setSku] = useState('')
  const [browseRow, setBrowseRow] = useState<number | null>(null)
  const [maxed, setMaxed] = useState(false)

  const rows = useMemo(() => products.data ?? [], [products.data])
  const productOptions = useMemo<ComboOption[]>(() => rows.filter((r) => r.product.active).map((r) => ({
    value: String(r.product.id), label: `${r.product.sku} · ${r.product.name}`, keywords: `${r.product.brand ?? ''} ${r.product.category ?? ''}`,
    render: (
      <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
        <span><b>{r.product.sku}</b> · {r.product.name}</span>
        <span className={r.onHand > 0 ? 'muted' : 'neg'} style={{ whiteSpace: 'nowrap' }}>{r.onHand > 0 ? `${qty(r.onHand)} ${r.product.baseUnit.name}` : 'out of stock'}</span>
      </div>
    ),
  })), [rows])
  const walkIn = customers.data?.find((c) => c.customer.walkIn)?.customer
  const customer = customers.data?.find((c) => String(c.customer.id) === customerId)
  const effectiveCustomerId = customerId || (type === 'RETAIL' && walkIn ? String(walkIn.id) : '')
  const isWalkIn = effectiveCustomerId === String(walkIn?.id)

  const calc = useMemo(() => {
    let gross = 0, discount = 0, tax = 0
    for (const l of lines) {
      if (!l.productId) continue
      const g = round2(toNum(l.qty) * toNum(l.rate))
      const d = Math.min(g, toNum(l.discount))
      const n = g - d
      gross += g; discount += d; tax += round2(n * toNum(l.taxPct) / 100)
    }
    return { gross: round2(gross), discount: round2(discount), tax: round2(tax), total: round2(gross - discount + tax) }
  }, [lines])

  // Retail cash sales default to "paid in full"; the user can still edit the amount.
  useEffect(() => { if (!paidTouched) setPaid(isWalkIn || type === 'RETAIL' ? String(calc.total) : '0') }, [calc.total, isWalkIn, type, paidTouched])

  const paidNum = Math.min(toNum(paid), calc.total)
  const balance = round2(calc.total - paidNum)
  const filled = lines.filter((l) => l.productId && toNum(l.qty) > 0)
  const setLine = (key: number, patch: Partial<Line>) => setLines((ls) => ls.map((l) => (l.key === key ? { ...l, ...patch } : l)))

  const buildBody = (override: boolean) => ({
    saleDate: date, type, customerId: effectiveCustomerId ? Number(effectiveCustomerId) : null, paymentMethod: paidNum > 0 ? method : 'CREDIT',
    accountId: paidNum > 0 && accountId ? Number(accountId) : null, paidAmount: paidNum, remarks, overrideCreditLimit: override,
    lines: filled.map((l) => ({
      productId: Number(l.productId), batchId: l.batchId && l.batchId !== ANY ? Number(l.batchId) : null, unitId: l.unitId ? Number(l.unitId) : null,
      qty: toNum(l.qty), rate: toNum(l.rate), discount: toNum(l.discount), taxPct: toNum(l.taxPct),
    })),
  })

  const [printAfter, setPrintAfter] = useState(false)
  const customerOptions = useMemo<ComboOption[]>(() => (customers.data ?? []).filter((c) => c.customer.active && (type === 'RETAIL' || !c.customer.walkIn)).map((c) => ({
    value: String(c.customer.id), label: c.customer.walkIn ? 'Walk-in customer (cash sale)' : c.customer.name, keywords: `${c.customer.code} ${c.customer.phone ?? ''} ${c.customer.address ?? ''}`,
  })), [customers.data, type])
  const save = useAction((override: boolean) => Api.createSale(buildBody(override)), {
    ok: 'Invoice created',
    invalidate: ['sales', 'products', 'customers', 'dashboard', 'accounts', 'report', 'product-batches'],
    onDone: (s: Sale) => navigate(`/sales/${s.id}${printAfter ? '?print=1' : ''}`),
    onFail: (msg) => {
      if (msg.startsWith('Credit limit exceeded') && confirm(`${msg}\n\nSell anyway?`)) save.mutate(true)
      else toast.err(msg)
    },
  })

  const addLine = () => { setLines((ls) => [...ls, newLine()]); focusCell(lines.length, 'product') }
  const nextLine = (i: number) => { if (i === lines.length - 1) addLine(); else focusCell(i + 1, 'product') }
  const firstEmpty = () => { const i = lines.findIndex((l) => !l.productId); return i < 0 ? lines.length : i }
  // Products ticked in the browse window fill the target line (if empty) and get a new line each after it; repeats add 1 to qty.
  const addProducts = (row: number, ids: string[]) => {
    if (!ids.length) return
    setLines((ls) => {
      const next = [...ls]
      let at = row
      for (const id of ids) {
        const dup = next.findIndex((l) => l.productId === id)
        if (dup >= 0) { next[dup] = { ...next[dup], qty: String(toNum(next[dup].qty) + 1) }; continue }
        const line = { ...newLine(), ...productPatch(rows, type, id) }
        if (next[at] && !next[at].productId) next.splice(at, 1, { ...line, key: next[at].key })
        else next.splice(at, 0, line)
        at++
      }
      return next
    })
    focusCell(row, 'qty')
  }

  const canSave = filled.length > 0 && filled.every((l) => toNum(l.rate) >= 0) && !!effectiveCustomerId && !save.isPending
  const creditNeedsCustomer = isWalkIn && balance > 0
  const submit = (print: boolean) => {
    if (!canSave || creditNeedsCustomer) { toast.err(creditNeedsCustomer ? 'A credit sale needs a named customer' : 'Add at least one product and pick a customer'); return }
    setPrintAfter(print)
    save.mutate(false)
  }
  useHotkeys({
    'ctrl+s': () => submit(false), 'ctrl+enter': () => submit(false), 'ctrl+p': () => submit(true),
    'alt+a': addLine, f2: addLine,
    f4: () => setBrowseRow(firstEmpty()), 'alt+w': () => setMaxed((m) => !m), escape: maxed ? () => setMaxed(false) : undefined,
    'alt+c': () => document.querySelector<HTMLInputElement>('[data-id="sale-customer"]')?.focus(),
    'alt+delete': () => {
      const el = document.activeElement
      const r = el?.hasAttribute('data-r') ? Number(el.getAttribute('data-r')) : -1
      if (lines.length > 1 && r >= 0) setLines((ls) => ls.filter((_, j) => j !== r))
    },
  })
  useEffect(() => { if (!products.isLoading && !customers.isLoading) focusCell(0, 'product') }, [products.isLoading, customers.isLoading])

  if (products.isLoading || customers.isLoading) return <Loading />

  function quickAdd() {
    const code = sku.trim().toLowerCase()
    if (!code) return
    const r = rows.find((x) => x.product.sku.toLowerCase() === code) ?? rows.find((x) => x.product.name.toLowerCase().includes(code))
    if (!r) { toast.err(`No product matches “${sku}”`); return }
    const existing = lines.find((l) => l.productId === String(r.product.id))
    if (existing) setLine(existing.key, { qty: String(toNum(existing.qty) + 1) })
    else {
      const fresh: Line = { ...newLine(), productId: String(r.product.id), rate: String(defaultRate(r, type, '')) }
      setLines((ls) => (ls.length === 1 && !ls[0].productId ? [fresh] : [...ls, fresh]))
    }
    setSku('')
    skuBox.current?.focus()
  }

  return (
    <div>
      <PageHeader kicker="Sales" title="New sale" blurb="One entry creates the invoice, deducts stock from the chosen container, records payment or credit, updates the customer ledger and calculates profit."
        actions={<button className="btn btn-ghost" onClick={() => navigate('/sales')}>Cancel</button>} />

      <div style={{ display: 'grid', gap: 18, gridTemplateColumns: 'minmax(0, 1fr) 340px', alignItems: 'start' }}>
        <div className="section-gap">
          <Card>
            <div className="form-grid">
              <Field label="Sale type">
                <Segmented<SaleType> value={type} onChange={(t) => { setType(t); setCustomerId(''); setPaidTouched(false); setLines((ls) => ls.map((l) => { const r = rows.find((x) => String(x.product.id) === l.productId); return l.rateTouched || !r ? l : { ...l, rate: String(defaultRate(r, t, l.unitId)) } })) }}
                  options={[{ value: 'RETAIL', label: 'Retail' }, { value: 'WHOLESALE', label: 'Wholesale' }]} />
              </Field>
              <Field label="Customer" span2>
                <Combobox options={customerOptions} value={effectiveCustomerId} placeholder="Type name, code or phone…" data={{ id: 'sale-customer' }}
                  onChange={(v) => { setCustomerId(v); setPaidTouched(false) }} onPicked={() => focusCell(0, 'product')} />
              </Field>
              <Field label="Date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
            </div>
            {customer && !isWalkIn && (
              <div style={{ marginTop: 12, display: 'flex', gap: 14, flexWrap: 'wrap', fontSize: 13 }} className="text-2">
                <span>Current balance <b className={customer.balance > 0 ? 'neg' : ''}>Rs {money(customer.balance)}</b></span>
                {customer.customer.creditLimit > 0 && <span>Credit limit <b>Rs {money(customer.customer.creditLimit)}</b></span>}
                {customer.customer.phone && <span>{customer.customer.phone}</span>}
              </div>
            )}
          </Card>

          <Card title={`Items${filled.length ? ` · ${filled.length}` : ''}`} pad={false} className={maxed ? 'card-max' : ''}
            actions={
              <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                <div className="search-box" style={{ width: 250 }}>
                  <Icon name="search" size={16} />
                  <input ref={skuBox} className="input" style={{ height: 34 }} placeholder="Scan code, press Enter to add" value={sku}
                    onChange={(e) => setSku(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); quickAdd() } }} />
                </div>
                <button className="btn btn-secondary btn-sm" onClick={() => setBrowseRow(firstEmpty())}><Icon name="list" size={15} /> All products<Kbd>F4</Kbd></button>
                <button className="btn btn-secondary btn-sm" onClick={() => setMaxed((m) => !m)}>
                  <Icon name={maxed ? 'shrink' : 'expand'} size={15} /> {maxed ? 'Close window' : 'Open in window'}<Kbd>{maxed ? 'Esc' : 'Alt+W'}</Kbd>
                </button>
              </div>
            }>
            <div className="table-scroll">
              <table className="tbl compact">
                <thead><tr><th>Product</th><th>Container</th><th className="n">Qty</th><th>Unit</th><th className="n">Rate</th><th className="n">Discount</th><th className="n">Tax %</th><th className="n">Total</th><th /></tr></thead>
                <tbody>
                  {lines.map((l, i) => (
                    <LineRow key={l.key} line={l} index={i} rows={rows} options={productOptions} type={type} onChange={(p) => setLine(l.key, p)}
                      onRemove={() => setLines((ls) => ls.filter((x) => x.key !== l.key))} removable={lines.length > 1} onQtyEnter={() => nextLine(i)} onBrowse={() => setBrowseRow(i)} />
                  ))}
                </tbody>
              </table>
            </div>
            <div style={{ padding: 14 }}><button className="btn btn-secondary btn-sm" onClick={addLine}><Icon name="plus" size={15} /> Add item<Kbd>Alt+A</Kbd></button></div>
          </Card>

          {browseRow !== null && (
            <ProductBrowser rows={rows} mode="sale" current={lines[browseRow]?.productId} onClose={() => setBrowseRow(null)}
              onPick={(id) => {
                const target = lines[browseRow]
                if (target) { setLine(target.key, productPatch(rows, type, id)); focusCell(browseRow, 'qty') }
                else addProducts(browseRow, [id])
              }}
              onPickMany={(ids) => addProducts(browseRow, ids)} />
          )}

          <Card title="Remarks"><textarea className="textarea" value={remarks} onChange={(e) => setRemarks(e.target.value)} placeholder="Notes printed on the invoice (optional)" /></Card>
        </div>

        <div style={{ position: 'sticky', top: 84 }} className="section-gap">
          <Card title="Summary">
            <div style={{ display: 'grid', gap: 9, fontSize: 13.5 }}>
              <Row k="Subtotal" v={money(calc.gross)} />
              <Row k="Discount" v={`– ${money(calc.discount)}`} />
              <Row k="Tax" v={money(calc.tax)} />
              <div style={{ borderTop: '1px solid var(--line)', paddingTop: 10, display: 'flex', justifyContent: 'space-between', fontSize: 18, fontWeight: 780 }}>
                <span>Total</span><span className="tabnum">Rs {money(calc.total)}</span>
              </div>
            </div>
          </Card>
          <Card title="Payment">
            <div className="section-gap" style={{ gap: 12 }}>
              <Field label="Payment method">
                <select className="select" value={method} onChange={(e) => setMethod(e.target.value)}>{METHODS.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}</select>
              </Field>
              <Field label="Received into">
                <select className="select" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
                  <option value="">{method === 'CASH' ? 'Default cash account' : 'Default bank account'}</option>
                  {accounts.data?.filter((a) => a.account.active).map((a) => <option key={a.account.id} value={a.account.id}>{a.account.name}</option>)}
                </select>
              </Field>
              <Field label="Amount paid now">
                <input className="input num" type="number" min="0" max={calc.total} value={paid} onChange={(e) => { setPaid(e.target.value); setPaidTouched(true) }} />
              </Field>
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn btn-secondary btn-sm" onClick={() => { setPaid(String(calc.total)); setPaidTouched(true) }}>Paid in full</button>
                <button className="btn btn-secondary btn-sm" onClick={() => { setPaid('0'); setPaidTouched(true) }}>On credit</button>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 700 }}>
                <span>Remaining balance</span><span className={balance > 0 ? 'neg tabnum' : 'pos tabnum'}>Rs {money(balance)}</span>
              </div>
            </div>
          </Card>
          {creditNeedsCustomer && <Banner tone="warn" icon="alert">A credit sale needs a named customer. Switch to Wholesale or pick a customer.</Banner>}
          <div style={{ display: 'grid', gap: 10 }}>
            <button className="btn btn-primary" style={{ height: 42 }} disabled={!canSave || creditNeedsCustomer} onClick={() => submit(false)}>
              <Icon name="check" size={16} /> {save.isPending ? 'Saving…' : 'Save invoice'}<Kbd>Ctrl+S</Kbd>
            </button>
            <button className="btn btn-secondary" disabled={!canSave || creditNeedsCustomer} onClick={() => submit(true)}>
              <Icon name="printer" size={16} /> Save &amp; print<Kbd>Ctrl+P</Kbd>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

function Row({ k, v }: { k: string; v: string }) {
  return <div style={{ display: 'flex', justifyContent: 'space-between' }}><span className="text-2">{k}</span><span className="tabnum">{v}</span></div>
}
