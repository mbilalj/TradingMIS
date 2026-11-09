import { useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import { useProducts, useSuppliers, useWarehouses } from '../api/hooks'
import type { Product } from '../api/types'
import Icon from '../components/Icon'
import { useToast } from '../components/Toast'
import Combobox from '../components/Combobox'
import ProductBrowser from '../components/ProductBrowser'
import { Banner, Card, Field, Kbd, Loading, PageHeader } from '../components/ui'
import { enterTo, focusCell } from '../lib/focus'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, money, round2, today, toNum } from '../lib/format'
import { useAction } from '../lib/useAction'

interface Line { productId: string; batchNo: string; unitId: string; qty: string; unitCost: string }
const emptyLine: Line = { productId: '', batchNo: '', unitId: '', qty: '', unitCost: '' }

export default function ReceivingFormPage() {
  const navigate = useNavigate()
  const toast = useToast()
  const products = useProducts()
  const suppliers = useSuppliers()
  const warehouses = useWarehouses()
  const files = useRef<HTMLInputElement>(null)

  const [containerNo, setContainerNo] = useState('')
  const [shipmentNo, setShipmentNo] = useState('')
  const [date, setDate] = useState(today())
  const [supplierId, setSupplierId] = useState('')
  const [warehouseId, setWarehouseId] = useState('')
  const [notes, setNotes] = useState('')
  const [payable, setPayable] = useState('')
  const [lines, setLines] = useState<Line[]>([{ ...emptyLine }])
  const [docs, setDocs] = useState<File[]>([])
  const [browseRow, setBrowseRow] = useState<number | null>(null)
  const [maxed, setMaxed] = useState(false)

  const productById = (id: string): Product | undefined => products.data?.find((r) => String(r.product.id) === id)?.product
  const total = lines.reduce((s, l) => s + round2(toNum(l.qty) * toNum(l.unitCost)), 0)
  const setLine = (i: number, patch: Partial<Line>) => setLines((ls) => ls.map((l, j) => (j === i ? { ...l, ...patch } : l)))

  const save = useAction(
    async () => {
      const shipment = await Api.receive({
        shipmentNo: shipmentNo || null, containerNo: containerNo.trim(), arrivalDate: date, supplierId: Number(supplierId), warehouseId: warehouseId ? Number(warehouseId) : null,
        notes, payableAmount: toNum(payable),
        lines: lines.filter((l) => l.productId).map((l) => ({
          productId: Number(l.productId), batchNo: l.batchNo || null, unitId: l.unitId ? Number(l.unitId) : null,
          qty: toNum(l.qty), unitCost: toNum(l.unitCost),
        })),
      })
      for (const f of docs) await Api.upload('SHIPMENT', shipment.id, f)
      return shipment
    },
    { ok: 'Stock received and added to inventory', onDone: (s) => navigate(`/shipments/${s.id}`) },
  )

  const addLine = () => { setLines((ls) => [...ls, { ...emptyLine }]); focusCell(lines.length, 'product') }
  // Products ticked in the browse window fill the current line (if empty) and get a new line each after it.
  const firstEmpty = () => { const i = lines.findIndex((l) => !l.productId); return i < 0 ? lines.length : i }
  const addProducts = (row: number, ids: string[]) => {
    if (!ids.length) return
    setLines((ls) => {
      const fresh = ids.filter((id) => !ls.some((l) => l.productId === id)).map((id) => ({ ...emptyLine, productId: id }))
      if (!fresh.length) return ls
      const next = [...ls]
      if (!next[row]?.productId) next.splice(row, 1, fresh.shift()!)
      next.splice(row + 1, 0, ...fresh)
      return next
    })
    focusCell(row, 'qty')
  }
  const valid = !!containerNo.trim() && supplierId && lines.some((l) => l.productId && toNum(l.qty) > 0 && l.unitCost !== '')
  const payableNum = toNum(payable)
  const trySave = () => {
    if (save.isPending || payableNum > total) return
    if (valid) save.mutate()
    else toast.err('Enter the container number, pick a supplier and add at least one product with quantity and cost')
  }
  useHotkeys({
    'ctrl+s': trySave, 'ctrl+enter': trySave, 'alt+a': addLine, f2: addLine,
    f4: () => setBrowseRow(firstEmpty()),
    'alt+w': () => setMaxed((m) => !m), escape: maxed ? () => setMaxed(false) : undefined,
    'alt+delete': () => {
      const r = Number(document.activeElement?.getAttribute('data-r'))
      if (lines.length > 1 && Number.isInteger(r) && r >= 0 && document.activeElement?.hasAttribute('data-r')) setLines((ls) => ls.filter((_, j) => j !== r))
    },
  })
  const supplierOptions = (suppliers.data ?? []).filter((s) => s.supplier.active).map((s) => ({
    value: String(s.supplier.id), label: s.supplier.name, keywords: `${s.supplier.code} ${s.supplier.country ?? ''}`,
    render: <span><b>{s.supplier.name}</b> <span className="muted">· {s.supplier.country ?? s.supplier.code}</span></span>,
  }))
  const productOptions = (products.data ?? []).filter((r) => r.product.active).map((r) => ({
    value: String(r.product.id), label: `${r.product.sku} · ${r.product.name}`, keywords: `${r.product.brand ?? ''} ${r.product.category ?? ''}`,
    render: <span><b>{r.product.sku}</b> · {r.product.name} <span className="muted">· {r.product.baseUnit.name}</span></span>,
  }))
  if (products.isLoading || suppliers.isLoading) return <Loading />

  return (
    <div>
      <PageHeader kicker="Inventory · Stock receiving" title="Receive container" blurb="Record a container arriving at the warehouse; every product in it becomes a batch of that container. Stock increases as soon as you save. Enter the final cost yourself — import costing is handled outside this system."
        actions={<button className="btn btn-ghost" onClick={() => navigate('/receiving')}>Cancel</button>} />

      <div className="section-gap">
        <Card title="Container details">
          <div className="form-grid">
            <Field label="Container number" hint="Required. Batches are numbered from it, e.g. MSKU4417823-01."><input className="input" value={containerNo} onChange={(e) => setContainerNo(e.target.value.toUpperCase())} placeholder="e.g. MSKU4417823" autoFocus /></Field>
            <Field label="Receiving record no." hint="Leave blank to auto-number (SHP-000001)."><input className="input" value={shipmentNo} onChange={(e) => setShipmentNo(e.target.value)} placeholder="e.g. SHP-001" /></Field>
            <Field label="Date received"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
            <Field label="Supplier">
              <Combobox options={supplierOptions} value={supplierId} onChange={setSupplierId} placeholder="Type to find supplier…" />
            </Field>
            <Field label="Warehouse">
              <select className="select" value={warehouseId} onChange={(e) => setWarehouseId(e.target.value)}>
                {warehouses.data?.map((w) => <option key={w.id} value={w.id}>{w.name}</option>)}
              </select>
            </Field>
            <Field label="Notes" span2><input className="input" value={notes} onChange={(e) => setNotes(e.target.value)} /></Field>
          </div>
        </Card>

        <Card title={`Products in this container${lines.some((l) => l.productId) ? ` · ${lines.filter((l) => l.productId).length}` : ''}`} sub="One batch is created per line, so the same product can carry a different cost in every container." pad={false}
          className={maxed ? 'card-max' : ''}
          actions={<div style={{ display: 'flex', gap: 8 }}>
            <button className="btn btn-secondary btn-sm" onClick={() => setBrowseRow(firstEmpty())}>
              <Icon name="list" size={15} /> All products<Kbd>F4</Kbd>
            </button>
            <button className="btn btn-secondary btn-sm" onClick={() => setMaxed((m) => !m)}>
              <Icon name={maxed ? 'shrink' : 'expand'} size={15} /> {maxed ? 'Close window' : 'Open in window'}<Kbd>{maxed ? 'Esc' : 'Alt+W'}</Kbd>
            </button>
          </div>}>
          <div className="table-scroll">
            <table className="tbl">
              <thead><tr><th style={{ minWidth: 260 }}>Product</th><th style={{ width: 150 }}>Batch no.</th><th style={{ width: 120 }} className="n">Quantity</th><th style={{ width: 130 }}>Unit</th><th style={{ width: 150 }} className="n">Final cost / unit</th><th className="n" style={{ width: 140 }}>Line total</th><th style={{ width: 44 }} /></tr></thead>
              <tbody>
                {lines.map((l, i) => {
                  const p = productById(l.productId)
                  const unitOptions = p ? [p.baseUnit, ...p.units.map((u) => u.unit)] : []
                  const factor = p && l.unitId ? (p.units.find((u) => String(u.unit.id) === l.unitId)?.factor ?? 1) : 1
                  return (
                    <tr key={i}>
                      <td>
                        <Combobox small options={productOptions} value={l.productId} placeholder="Type code or name…  (F4 = all)" data={{ r: i, f: 'product' }}
                          onChange={(v) => setLine(i, { productId: v, unitId: '' })} onPicked={() => focusCell(i, 'qty')} onBrowse={() => setBrowseRow(i)} />
                      </td>
                      <td><input className="input input-sm" value={l.batchNo} onChange={(e) => setLine(i, { batchNo: e.target.value })} placeholder="auto" data-r={i} data-f="batch" /></td>
                      <td><input className="input input-sm num" type="number" min="0" value={l.qty} onChange={(e) => setLine(i, { qty: e.target.value })} data-r={i} data-f="qty" onKeyDown={enterTo(() => focusCell(i, 'cost'))} /></td>
                      <td>
                        <select className="select select-sm" value={l.unitId || (p ? String(p.baseUnit.id) : '')} onChange={(e) => setLine(i, { unitId: e.target.value })} disabled={!p}>
                          {unitOptions.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
                        </select>
                        {factor !== 1 && p && <div className="muted" style={{ fontSize: 11 }}>= {fmt(toNum(l.qty) * factor)} {p.baseUnit.name}</div>}
                      </td>
                      <td><input className="input input-sm num" type="number" min="0" value={l.unitCost} onChange={(e) => setLine(i, { unitCost: e.target.value })} data-r={i} data-f="cost"
                        onKeyDown={enterTo(() => { if (i === lines.length - 1) addLine(); else focusCell(i + 1, 'product') })} /></td>
                      <td className="n" style={{ fontWeight: 650 }}>{money(round2(toNum(l.qty) * toNum(l.unitCost)))}</td>
                      <td>{lines.length > 1 && <button className="btn btn-ghost btn-sm btn-icon" onClick={() => setLines((ls) => ls.filter((_, j) => j !== i))} aria-label="Remove line"><Icon name="trash" size={15} /></button>}</td>
                    </tr>
                  )
                })}
              </tbody>
              <tfoot><tr><td colSpan={5}>Shipment value</td><td className="n">{money(total)}</td><td /></tr></tfoot>
            </table>
          </div>
          <div style={{ padding: 14 }}><button className="btn btn-secondary btn-sm" onClick={addLine}><Icon name="plus" size={15} /> Add product line<Kbd>Alt+A</Kbd></button></div>
        </Card>

        {browseRow !== null && (
          <ProductBrowser rows={products.data ?? []} mode="purchase" current={lines[browseRow]?.productId} onClose={() => setBrowseRow(null)}
            onPick={(id) => {
              if (browseRow < lines.length) { setLine(browseRow, { productId: id, unitId: '' }); focusCell(browseRow, 'qty') }
              else addProducts(browseRow, [id])
            }}
            onPickMany={(ids) => addProducts(browseRow, ids)} />
        )}

        <div style={{ display: 'grid', gap: 16, gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))' }}>
          <Card title="Supplier payable" sub="Only if you still owe the supplier for this shipment.">
            <Field label="Amount still owed to supplier" hint={`Of Rs ${money(total)} shipment value. The rest is treated as already settled outside this system.`}>
              <input className="input num" type="number" min="0" max={total} value={payable} onChange={(e) => setPayable(e.target.value)} placeholder="0.00" />
            </Field>
            {payableNum > total && <div className="neg" style={{ marginTop: 8 }}>Cannot exceed the shipment value.</div>}
          </Card>
          <Card title="Supporting documents" sub="Packing list, invoice, clearing papers — optional.">
            <input ref={files} type="file" multiple hidden onChange={(e) => { setDocs((d) => [...d, ...Array.from(e.target.files ?? [])]); e.target.value = '' }} />
            {docs.map((f, i) => (
              <div key={i} style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 6 }}>
                <Icon name="file" size={16} /> <span style={{ flex: 1 }}>{f.name}</span>
                <button className="btn btn-ghost btn-sm btn-icon" onClick={() => setDocs((d) => d.filter((_, j) => j !== i))} aria-label="Remove"><Icon name="x" size={15} /></button>
              </div>
            ))}
            <button className="btn btn-secondary btn-sm" onClick={() => files.current?.click()}><Icon name="clip" size={15} /> Attach files</button>
          </Card>
        </div>

        <Banner icon="info">Customs duty, clearing and freight you pay for this container are not part of this form. Record them under <b>Expenses → Non-operating payment</b> and link them to this shipment — they will reduce cash/bank but not profit.</Banner>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <button className="btn btn-ghost" onClick={() => navigate('/receiving')}>Cancel</button>
          <button className="btn btn-primary" disabled={!valid || save.isPending || payableNum > total}
            onClick={trySave}>
            <Icon name="check" size={16} /> {save.isPending ? 'Saving…' : 'Save & add to stock'}<Kbd>Ctrl+S</Kbd>
          </button>
        </div>
      </div>
    </div>
  )
}
