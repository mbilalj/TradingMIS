import { useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Api } from '../api/resources'
import { useProducts, useUnits } from '../api/hooks'
import type { Product, ProductRow } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import { Badge, Banner, Field, Kbd, Loading, Modal, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, money, qty } from '../lib/format'
import { useAction } from '../lib/useAction'

interface Form {
  sku: string; name: string; category: string; brand: string; description: string; baseUnitId: string
  sellingPrice: string; wholesalePrice: string; retailPrice: string; minStock: string; active: boolean
  units: { unitId: string; factor: string }[]
}

const blank: Form = {
  sku: '', name: '', category: '', brand: '', description: '', baseUnitId: '', sellingPrice: '', wholesalePrice: '',
  retailPrice: '', minStock: '', active: true, units: [],
}

function toForm(p: Product): Form {
  return {
    sku: p.sku, name: p.name, category: p.category ?? '', brand: p.brand ?? '', description: p.description ?? '',
    baseUnitId: String(p.baseUnit.id), sellingPrice: String(p.sellingPrice ?? ''), wholesalePrice: String(p.wholesalePrice ?? ''),
    retailPrice: String(p.retailPrice ?? ''), minStock: String(p.minStock ?? ''), active: p.active,
    units: p.units.map((u) => ({ unitId: String(u.unit.id), factor: String(u.factor) })),
  }
}

export default function ProductsPage() {
  const { user } = useAuth()
  const [params] = useSearchParams()
  const products = useProducts()
  const units = useUnits()
  const [editing, setEditing] = useState<{ id: number | null; form: Form } | null>(null)
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive' | 'low'>('all')
  const [category, setCategory] = useState('')
  const editable = canEdit(user?.role, 'products')
  const openNew = () => setEditing({ id: null, form: { ...blank, baseUnitId: String(units.data?.[0]?.id ?? '') } })
  useHotkeys({ 'alt+n': editable ? openNew : undefined })

  const categories = useMemo(() => [...new Set((products.data ?? []).map((r) => r.product.category).filter(Boolean))] as string[], [products.data])
  const rows = useMemo(() => (products.data ?? []).filter((r) =>
    (filter === 'all' || (filter === 'active' && r.product.active) || (filter === 'inactive' && !r.product.active) || (filter === 'low' && r.lowStock))
    && (!category || r.product.category === category)), [products.data, filter, category])

  const save = useAction(
    (v: { id: number | null; form: Form }) => Api.saveProduct(v.id, {
      sku: v.form.sku, name: v.form.name, category: v.form.category, brand: v.form.brand, description: v.form.description,
      baseUnitId: Number(v.form.baseUnitId), sellingPrice: Number(v.form.sellingPrice) || 0, wholesalePrice: Number(v.form.wholesalePrice) || 0,
      retailPrice: Number(v.form.retailPrice) || 0, minStock: Number(v.form.minStock) || 0, active: v.form.active,
      units: v.form.units.filter((u) => u.unitId && Number(u.factor) > 0).map((u) => ({ unitId: Number(u.unitId), factor: Number(u.factor) })),
    }),
    { ok: 'Product saved', invalidate: ['products'], onDone: () => setEditing(null) },
  )

  if (products.isLoading) return <Loading />
  const f = editing?.form
  const set = (patch: Partial<Form>) => setEditing((s) => (s ? { ...s, form: { ...s.form, ...patch } } : s))
  const baseUnit = units.data?.find((u) => String(u.id) === f?.baseUnitId)

  return (
    <div>
      <PageHeader kicker="Inventory" title="Products" blurb="The product master: codes, units and conversions, prices and minimum stock. Cost is entered per batch when stock is received."
        actions={editable && <button className="btn btn-primary" onClick={openNew}><Icon name="plus" size={16} /> New product<Kbd>Alt+N</Kbd></button>} />

      <DataTable<ProductRow>
        searchable searchPlaceholder="Search name, code, brand or category…"
        rows={rows} keyOf={(r) => r.product.id} onEdit={editable ? (r) => setEditing({ id: r.product.id, form: toForm(r.product) }) : undefined}
        toolbar={
          <div style={{ display: 'flex', gap: 10 }}>
            <select className="select select-sm" style={{ width: 170 }} value={category} onChange={(e) => setCategory(e.target.value)}>
              <option value="">All categories</option>
              {categories.map((c) => <option key={c}>{c}</option>)}
            </select>
            <select className="select select-sm" style={{ width: 150 }} value={filter} onChange={(e) => setFilter(e.target.value as typeof filter)}>
              <option value="all">All products</option><option value="active">Active</option><option value="inactive">Inactive</option><option value="low">Low stock</option>
            </select>
          </div>
        }
        columns={[
          { label: 'Code', search: (r) => `${r.product.sku} ${r.product.name} ${r.product.brand ?? ''} ${r.product.category ?? ''} ${params.get('q') ?? ''}`, render: (r) => <b>{r.product.sku}</b> },
          { label: 'Product', render: (r) => (<div><div style={{ fontWeight: 650 }}>{r.product.name}</div><div className="muted" style={{ fontSize: 12 }}>{[r.product.brand, r.product.category].filter(Boolean).join(' · ')}</div></div>) },
          { label: 'Unit', render: (r) => (<div>{r.product.baseUnit.name}{r.product.units.length > 0 && <div className="muted" style={{ fontSize: 11.5 }}>{r.product.units.map((u) => `1 ${u.unit.name} = ${qty(u.factor)}`).join(' · ')}</div>}</div>) },
          { label: 'In stock', numeric: true, render: (r) => <span className={r.lowStock ? 'neg' : ''} style={{ fontWeight: 650 }}>{qty(r.onHand)}</span> },
          { label: 'Min', numeric: true, render: (r) => qty(r.product.minStock) },
          { label: 'Last cost', numeric: true, render: (r) => (r.lastCost ? money(r.lastCost) : <span className="muted">—</span>) },
          { label: 'Wholesale', numeric: true, render: (r) => money(r.product.wholesalePrice) },
          { label: 'Retail', numeric: true, render: (r) => money(r.product.retailPrice) },
          { label: 'Stock value', numeric: true, render: (r) => fmt(r.stockValue) },
          { label: 'Status', render: (r) => (r.lowStock ? <Badge tone="danger">Low stock</Badge> : r.product.active ? <Badge tone="success">Active</Badge> : <Badge>Inactive</Badge>) },
          { label: '', render: (r) => editable && <button className="btn btn-ghost btn-sm" onClick={() => setEditing({ id: r.product.id, form: toForm(r.product) })}><Icon name="edit" size={15} /> Edit</button> },
        ]}
        emptyText="No products yet. Add your first product to start receiving stock."
      />

      {editing && f && (
        <Modal wide title={editing.id ? `Edit ${f.sku}` : 'New product'} onClose={() => setEditing(null)}
          footer={<>
            <button className="btn btn-ghost" onClick={() => setEditing(null)}>Cancel</button>
            <button className="btn btn-primary" disabled={save.isPending || !f.sku || !f.name || !f.baseUnitId} onClick={() => save.mutate(editing)}>{save.isPending ? 'Saving…' : 'Save product'}</button>
          </>}>
          <div className="form-grid">
            <Field label="Product code / SKU"><input className="input" value={f.sku} onChange={(e) => set({ sku: e.target.value })} autoFocus /></Field>
            <Field label="Product name" span2><input className="input" value={f.name} onChange={(e) => set({ name: e.target.value })} /></Field>
            <Field label="Category"><input className="input" list="cats" value={f.category} onChange={(e) => set({ category: e.target.value })} /><datalist id="cats">{categories.map((c) => <option key={c} value={c} />)}</datalist></Field>
            <Field label="Brand"><input className="input" value={f.brand} onChange={(e) => set({ brand: e.target.value })} /></Field>
            <Field label="Unit of measurement" hint={editing.id ? 'Fixed once the product exists — add a conversion for other units.' : 'Stock is counted in this base unit.'}>
              <select className="select" value={f.baseUnitId} disabled={!!editing.id} onChange={(e) => set({ baseUnitId: e.target.value })}>
                {units.data?.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
              </select>
            </Field>
            <Field label="Minimum stock level"><input className="input num" type="number" min="0" value={f.minStock} onChange={(e) => set({ minStock: e.target.value })} /></Field>
            <Field label="Selling price"><input className="input num" type="number" min="0" value={f.sellingPrice} onChange={(e) => set({ sellingPrice: e.target.value })} /></Field>
            <Field label="Wholesale price"><input className="input num" type="number" min="0" value={f.wholesalePrice} onChange={(e) => set({ wholesalePrice: e.target.value })} /></Field>
            <Field label="Retail price"><input className="input num" type="number" min="0" value={f.retailPrice} onChange={(e) => set({ retailPrice: e.target.value })} /></Field>
            <Field label="Status">
              <select className="select" value={f.active ? 'a' : 'i'} onChange={(e) => set({ active: e.target.value === 'a' })}><option value="a">Active</option><option value="i">Inactive</option></select>
            </Field>
            <Field label="Description" span2><textarea className="textarea" value={f.description} onChange={(e) => set({ description: e.target.value })} /></Field>
          </div>

          <div style={{ marginTop: 22 }}>
            <div className="card-title">Unit conversions</div>
            <div className="card-sub" style={{ marginBottom: 10 }}>Optional. Example: 1 Carton = 200 Piece, 1 Box = 10 Piece. Each product has its own conversions.</div>
            <div style={{ display: 'grid', gap: 8 }}>
              {f.units.map((u, i) => (
                <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                  <span className="text-2">1</span>
                  <select className="select select-sm" style={{ width: 150 }} value={u.unitId} onChange={(e) => set({ units: f.units.map((x, j) => (j === i ? { ...x, unitId: e.target.value } : x)) })}>
                    <option value="">Unit…</option>
                    {units.data?.filter((x) => String(x.id) !== f.baseUnitId).map((x) => <option key={x.id} value={x.id}>{x.name}</option>)}
                  </select>
                  <span className="text-2">=</span>
                  <input className="input input-sm num" type="number" min="0" style={{ width: 120 }} value={u.factor} onChange={(e) => set({ units: f.units.map((x, j) => (j === i ? { ...x, factor: e.target.value } : x)) })} />
                  <span className="text-2">{baseUnit?.name ?? 'base unit'}</span>
                  <button className="btn btn-ghost btn-sm btn-icon" onClick={() => set({ units: f.units.filter((_, j) => j !== i) })} aria-label="Remove"><Icon name="trash" size={15} /></button>
                </div>
              ))}
            </div>
            <button className="btn btn-secondary btn-sm" style={{ marginTop: 10 }} onClick={() => set({ units: [...f.units, { unitId: '', factor: '' }] })}><Icon name="plus" size={15} /> Add conversion</button>
          </div>
          {!editing.id && <div style={{ marginTop: 18 }}><Banner icon="info">Product cost isn’t stored here. You enter the final cost for every shipment when you receive stock, so the same product can carry different costs by batch.</Banner></div>}
        </Modal>
      )}
    </div>
  )
}
