import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Api } from '../api/resources'
import { useProducts } from '../api/hooks'
import type { MovementType, ProductRow } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import Combobox from '../components/Combobox'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import ProductBrowser from '../components/ProductBrowser'
import ReportView from '../components/ReportView'
import { Badge, Banner, Field, Kbd, Kpi, Loading, Modal, PageHeader, Tabs } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, qty, today, toNum } from '../lib/format'
import { useAction } from '../lib/useAction'

type Tab = 'product' | 'batch' | 'movement' | 'adjustments'

function AdjustmentModal({ onClose }: { onClose: () => void }) {
  const products = useProducts()
  const [productId, setProductId] = useState('')
  const [batchId, setBatchId] = useState('')
  const [type, setType] = useState<MovementType>('DAMAGED')
  const [increase, setIncrease] = useState(false)
  const [amount, setAmount] = useState('')
  const [unitId, setUnitId] = useState('')
  const [reason, setReason] = useState('')
  const [date, setDate] = useState(today())
  const [browsing, setBrowsing] = useState(false)

  const product = products.data?.find((r) => String(r.product.id) === productId)?.product
  const batches = useQuery({
    queryKey: ['report', 'batch-wise-stock', productId],
    queryFn: () => Api.report('batch-wise-stock', { id: productId }),
    enabled: !!productId,
  })
  const batchRows = batches.data?.rows ?? []
  const batch = batchRows.find((r) => String(r.batch_id) === batchId)
  const canIncrease = type === 'CORRECTION' || type === 'OTHER_ADJUSTMENT'
  const units = product ? [product.baseUnit, ...product.units.map((u) => u.unit)] : []
  const productOptions = (products.data ?? []).map((r) => ({
    value: String(r.product.id), label: `${r.product.sku} · ${r.product.name}`, keywords: `${r.product.brand ?? ''} ${r.product.category ?? ''}`,
    render: <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}><span><b>{r.product.sku}</b> · {r.product.name}</span><span className="muted">in stock {qty(r.onHand)}</span></div>,
  }))

  const save = useAction(
    () => Api.adjustStock({ date, batchId: Number(batchId), type, increase: canIncrease && increase, unitId: unitId ? Number(unitId) : null, qty: toNum(amount), reason }),
    { ok: 'Stock adjusted', onDone: onClose },
  )

  return (
    <Modal title="Stock adjustment" onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary" disabled={save.isPending || !batchId || toNum(amount) <= 0 || !reason.trim()} onClick={() => save.mutate(undefined)}>{save.isPending ? 'Saving…' : 'Post adjustment'}</button></>}>
      <div className="form-grid">
        <Field label="Adjustment type">
          <select className="select" value={type} onChange={(e) => setType(e.target.value as MovementType)}>
            <option value="DAMAGED">Damaged goods</option><option value="MISSING">Missing goods</option>
            <option value="CORRECTION">Physical stock correction</option><option value="OTHER_ADJUSTMENT">Other adjustment</option>
          </select>
        </Field>
        <Field label="Date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
        <Field label="Product" span2>
          <Combobox options={productOptions} value={productId} placeholder="Type code or name…  (F4 = all products)" onBrowse={() => setBrowsing(true)}
            onChange={(v) => { setProductId(v); setBatchId(''); setUnitId('') }} />
        </Field>
        <Field label="Batch" span2 hint={batch ? `On hand: ${qty(batch.on_hand as number)} · unit cost ${fmt(batch.cost as number)}` : undefined}>
          <select className="select" value={batchId} onChange={(e) => setBatchId(e.target.value)} disabled={!productId}>
            <option value="">Select batch…</option>
            {batchRows.map((r) => <option key={String(r.batch_id)} value={String(r.batch_id)}>{String(r.batch)} · shipment {String(r.shipment)} · {qty(r.on_hand as number)} left</option>)}
          </select>
        </Field>
        {canIncrease && (
          <Field label="Direction">
            <select className="select" value={increase ? 'up' : 'down'} onChange={(e) => setIncrease(e.target.value === 'up')}>
              <option value="down">Reduce stock (shortage)</option><option value="up">Increase stock (found / surplus)</option>
            </select>
          </Field>
        )}
        <Field label="Quantity"><input className="input num" type="number" min="0" value={amount} onChange={(e) => setAmount(e.target.value)} /></Field>
        <Field label="Unit">
          <select className="select" value={unitId || (product ? String(product.baseUnit.id) : '')} onChange={(e) => setUnitId(e.target.value)} disabled={!product}>
            {units.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
          </select>
        </Field>
        <Field label="Reason (required)" span2><input className="input" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="e.g. Water damage in rack C2 / cycle count difference" /></Field>
      </div>
      <div style={{ marginTop: 16 }}><Banner icon="info">The adjustment is recorded in the stock history with this reason, and its value (at the batch cost) is posted to the books as a stock loss or gain.</Banner></div>
      {browsing && <ProductBrowser rows={products.data ?? []} mode="purchase" current={productId} onClose={() => setBrowsing(false)}
        onPick={(v) => { setProductId(v); setBatchId(''); setUnitId('') }} />}
    </Modal>
  )
}

export default function StockPage() {
  const { user } = useAuth()
  const products = useProducts()
  const [tab, setTab] = useState<Tab>('product')
  const [adjusting, setAdjusting] = useState(false)
  useHotkeys({ 'alt+n': canEdit(user?.role, 'adjustments') ? () => setAdjusting(true) : undefined })

  const totals = useMemo(() => {
    const rows = products.data ?? []
    return { value: rows.reduce((s, r) => s + Number(r.stockValue), 0), low: rows.filter((r) => r.lowStock).length, items: rows.length, units: rows.reduce((s, r) => s + Number(r.onHand), 0) }
  }, [products.data])
  if (products.isLoading) return <Loading />

  return (
    <div>
      <PageHeader kicker="Inventory" title="Stock & batches" blurb="Live inventory by product and by shipment batch, with the full movement history behind every number."
        actions={canEdit(user?.role, 'adjustments') && <button className="btn btn-secondary" onClick={() => setAdjusting(true)}><Icon name="sliders" size={16} /> Stock adjustment<Kbd>Alt+N</Kbd></button>} />

      <div className="kpi-grid" style={{ marginBottom: 18 }}>
        <Kpi label="Products" value={totals.items} sub="in the product master" icon="box" />
        <Kpi label="Units on hand" value={fmt(totals.units)} sub="all base units combined" icon="layers" tone="info" />
        <Kpi label="Stock value" value={`Rs ${fmt(totals.value)}`} sub="at batch cost" icon="coins" tone="success" />
        <Kpi label="Low-stock products" value={totals.low} sub="at or below minimum" icon="alert" tone={totals.low ? 'danger' : 'success'} />
      </div>

      <Tabs<Tab> value={tab} onChange={setTab} options={[
        { value: 'product', label: 'By product' }, { value: 'batch', label: 'By batch / shipment' },
        { value: 'movement', label: 'Movement history' }, { value: 'adjustments', label: 'Adjustments & damaged' }]} />

      {tab === 'product' && (
        <DataTable<ProductRow> searchable searchPlaceholder="Search product or code…" rows={products.data ?? []} keyOf={(r) => r.product.id}
          columns={[
            { label: 'Code', search: (r) => `${r.product.sku} ${r.product.name} ${r.product.category ?? ''}`, render: (r) => <b>{r.product.sku}</b> },
            { label: 'Product', render: (r) => r.product.name },
            { label: 'Category', render: (r) => r.product.category ?? '—' },
            { label: 'Unit', render: (r) => r.product.baseUnit.name },
            { label: 'Available', numeric: true, render: (r) => <b className={r.lowStock ? 'neg' : ''}>{qty(r.onHand)}</b> },
            { label: 'Minimum', numeric: true, render: (r) => qty(r.product.minStock) },
            { label: 'Latest cost', numeric: true, render: (r) => fmt(r.lastCost) },
            { label: 'Stock value', numeric: true, render: (r) => fmt(r.stockValue) },
            { label: 'Level', render: (r) => (r.lowStock ? <Badge tone="danger">Reorder</Badge> : <Badge tone="success">OK</Badge>) },
          ]} />
      )}
      {tab === 'batch' && <ReportView code="batch-wise-stock" embedded />}
      {tab === 'movement' && <ReportView code="stock-movement" embedded />}
      {tab === 'adjustments' && <ReportView code="stock-adjustments" embedded />}

      {adjusting && <AdjustmentModal onClose={() => setAdjusting(false)} />}
    </div>
  )
}
