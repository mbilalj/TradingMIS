import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import { useSuppliers } from '../api/hooks'
import type { Supplier, SupplierPayment, SupplierRow } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit, canView } from '../auth/access'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import { Badge, Field, Kbd, Kpi, Loading, Modal, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, fmtDate, money, titleCase } from '../lib/format'
import { useAction } from '../lib/useAction'
import { PaySupplierModal } from './PaymentModals'

export interface SupplierForm { name: string; country: string; contact: string; address: string; openingBalance: string; notes: string; active: boolean }
const blank: SupplierForm = { name: '', country: '', contact: '', address: '', openingBalance: '', notes: '', active: true }
export const toSupplierForm = (s: Supplier): SupplierForm => ({ name: s.name, country: s.country ?? '', contact: s.contact ?? '', address: s.address ?? '', openingBalance: String(s.openingBalance), notes: s.notes ?? '', active: s.active })

export function SupplierModal({ id, initial, onClose }: { id: number | null; initial?: SupplierForm; onClose: () => void }) {
  const [f, setF] = useState<SupplierForm>(initial ?? blank)
  const set = (p: Partial<SupplierForm>) => setF((s) => ({ ...s, ...p }))
  const save = useAction(
    () => Api.saveSupplier(id, { name: f.name, country: f.country, contact: f.contact, address: f.address, openingBalance: Number(f.openingBalance) || 0, notes: f.notes, active: f.active }),
    { ok: 'Supplier saved', invalidate: ['suppliers', 'report', 'dashboard'], onDone: onClose },
  )
  return (
    <Modal title={id ? 'Edit supplier' : 'New supplier'} onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button><button className="btn btn-primary" disabled={!f.name.trim() || save.isPending} onClick={() => save.mutate(undefined)}>{save.isPending ? 'Saving…' : 'Save supplier'}</button></>}>
      <div className="form-grid">
        <Field label="Supplier name" span2><input className="input" value={f.name} onChange={(e) => set({ name: e.target.value })} autoFocus /></Field>
        <Field label="Country"><input className="input" value={f.country} onChange={(e) => set({ country: e.target.value })} /></Field>
        <Field label="Contact information"><input className="input" value={f.contact} onChange={(e) => set({ contact: e.target.value })} /></Field>
        <Field label="Address" span2><input className="input" value={f.address} onChange={(e) => set({ address: e.target.value })} /></Field>
        <Field label="Opening balance (Rs)" hint="Positive = you owe the supplier."><input className="input num" type="number" value={f.openingBalance} onChange={(e) => set({ openingBalance: e.target.value })} /></Field>
        <Field label="Status"><select className="select" value={f.active ? 'a' : 'i'} onChange={(e) => set({ active: e.target.value === 'a' })}><option value="a">Active</option><option value="i">Inactive</option></select></Field>
        <Field label="Notes" span2><textarea className="textarea" value={f.notes} onChange={(e) => set({ notes: e.target.value })} /></Field>
      </div>
    </Modal>
  )
}

export default function SuppliersPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const suppliers = useSuppliers()
  const [creating, setCreating] = useState(false)
  const [editing, setEditing] = useState<Supplier | null>(null)
  useHotkeys({ 'alt+n': canEdit(user?.role, 'suppliers') ? () => setCreating(true) : undefined })
  if (suppliers.isLoading) return <Loading />
  const rows = suppliers.data ?? []
  const owed = rows.reduce((s, r) => s + Math.max(0, Number(r.balance)), 0)
  const showMoney = canView(user?.role, 'supplierpay')

  return (
    <div>
      <PageHeader kicker="Payments" title="Suppliers" blurb="Who you buy from. Import purchasing happens elsewhere, but the supplier record keeps shipment history and any amount you still owe."
        actions={canEdit(user?.role, 'suppliers') && <button className="btn btn-primary" onClick={() => setCreating(true)}><Icon name="plus" size={16} /> New supplier<Kbd>Alt+N</Kbd></button>} />
      <div className="kpi-grid" style={{ marginBottom: 16 }}>
        <Kpi label="Suppliers" value={rows.length} icon="building" />
        {showMoney && <Kpi label="Total payable" value={`Rs ${fmt(owed)}`} sub="owed to suppliers" icon="card" tone="danger" />}
      </div>
      <DataTable<SupplierRow>
        searchable searchPlaceholder="Search name, code or country…" rows={rows} keyOf={(r) => r.supplier.id} onRowClick={(r) => navigate(`/suppliers/${r.supplier.id}`)} onEdit={canEdit(user?.role, 'suppliers') ? (r) => setEditing(r.supplier) : undefined}
        columns={[
          { label: 'Code', search: (r) => `${r.supplier.code} ${r.supplier.name} ${r.supplier.country ?? ''}`, render: (r) => <b>{r.supplier.code}</b> },
          { label: 'Supplier', render: (r) => (<div><div style={{ fontWeight: 650 }}>{r.supplier.name}</div><div className="muted" style={{ fontSize: 12 }}>{r.supplier.contact ?? ''}</div></div>) },
          { label: 'Country', render: (r) => r.supplier.country ?? '—' },
          ...(showMoney ? [{ label: 'We owe', numeric: true, render: (r: SupplierRow) => <b className={r.balance > 0 ? 'neg' : ''}>{money(r.balance)}</b> }] : []),
          { label: 'Status', render: (r) => (r.supplier.active ? <Badge tone="success">Active</Badge> : <Badge>Inactive</Badge>) },
        ]}
        emptyText="No suppliers yet."
      />
      {creating && <SupplierModal id={null} onClose={() => setCreating(false)} />}
      {editing && <SupplierModal id={editing.id} initial={toSupplierForm(editing)} onClose={() => setEditing(null)} />}
    </div>
  )
}

export function SupplierPaymentsPage() {
  const { user } = useAuth()
  const [adding, setAdding] = useState(false)
  useHotkeys({ 'alt+n': canEdit(user?.role, 'supplierpay') ? () => setAdding(true) : undefined })
  const { data, isLoading } = useQuery({ queryKey: ['supplier-payments'], queryFn: Api.supplierPayments })
  if (isLoading) return <Loading />
  return (
    <div>
      <PageHeader kicker="Payments" title="Supplier payments" blurb="Payments made against what you owe suppliers."
        actions={canEdit(user?.role, 'supplierpay') && <button className="btn btn-primary" onClick={() => setAdding(true)}><Icon name="plus" size={16} /> Pay supplier<Kbd>Alt+N</Kbd></button>} />
      <DataTable<SupplierPayment>
        searchable searchPlaceholder="Search payment, supplier or reference…" rows={data ?? []} keyOf={(r) => r.id}
        columns={[
          { label: 'Payment', search: (r) => `${r.paymentNo} ${r.supplier.name} ${r.reference ?? ''}`, render: (r) => <b>{r.paymentNo}</b> },
          { label: 'Date', render: (r) => fmtDate(r.paymentDate) },
          { label: 'Supplier', render: (r) => r.supplier.name },
          { label: 'Method', render: (r) => (r.method ? titleCase(r.method) : '—') },
          { label: 'Reference', render: (r) => r.reference ?? <span className="muted">—</span> },
          { label: 'Paid from', render: (r) => r.account.name },
          { label: 'Amount', numeric: true, render: (r) => <b>{money(r.amount)}</b> },
        ]}
        emptyText="No supplier payments yet."
      />
      {adding && <PaySupplierModal onClose={() => setAdding(false)} />}
    </div>
  )
}
