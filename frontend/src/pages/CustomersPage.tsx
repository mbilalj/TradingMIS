import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import { useCustomers } from '../api/hooks'
import type { Customer, CustomerRow, SaleType } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import { Badge, Field, Kbd, Kpi, Loading, Modal, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, money } from '../lib/format'
import { useAction } from '../lib/useAction'

export interface CustomerForm {
  name: string; phone: string; address: string; type: SaleType; openingBalance: string; creditLimit: string; creditDays: string; notes: string; active: boolean
}
const blank: CustomerForm = { name: '', phone: '', address: '', type: 'WHOLESALE', openingBalance: '', creditLimit: '', creditDays: '30', notes: '', active: true }

export function toCustomerForm(c: Customer): CustomerForm {
  return { name: c.name, phone: c.phone ?? '', address: c.address ?? '', type: c.type, openingBalance: String(c.openingBalance), creditLimit: String(c.creditLimit), creditDays: String(c.creditDays), notes: c.notes ?? '', active: c.active }
}

export function CustomerModal({ id, initial, onClose }: { id: number | null; initial?: CustomerForm; onClose: () => void }) {
  const [f, setF] = useState<CustomerForm>(initial ?? blank)
  const set = (p: Partial<CustomerForm>) => setF((s) => ({ ...s, ...p }))
  const save = useAction(
    () => Api.saveCustomer(id, { name: f.name, phone: f.phone, address: f.address, type: f.type, openingBalance: Number(f.openingBalance) || 0, creditLimit: Number(f.creditLimit) || 0, creditDays: Number(f.creditDays) || 0, notes: f.notes, active: f.active }),
    { ok: 'Customer saved', invalidate: ['customers', 'report', 'dashboard'], onDone: onClose },
  )
  return (
    <Modal title={id ? 'Edit customer' : 'New customer'} onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button><button className="btn btn-primary" disabled={!f.name.trim() || save.isPending} onClick={() => save.mutate(undefined)}>{save.isPending ? 'Saving…' : 'Save customer'}</button></>}>
      <div className="form-grid">
        <Field label="Customer name" span2><input className="input" value={f.name} onChange={(e) => set({ name: e.target.value })} autoFocus /></Field>
        <Field label="Contact number"><input className="input" value={f.phone} onChange={(e) => set({ phone: e.target.value })} /></Field>
        <Field label="Customer type"><select className="select" value={f.type} onChange={(e) => set({ type: e.target.value as SaleType })}><option value="WHOLESALE">Wholesale</option><option value="RETAIL">Retail</option></select></Field>
        <Field label="Address" span2><input className="input" value={f.address} onChange={(e) => set({ address: e.target.value })} /></Field>
        <Field label="Opening balance (Rs)" hint="Positive = customer owes you."><input className="input num" type="number" value={f.openingBalance} onChange={(e) => set({ openingBalance: e.target.value })} /></Field>
        <Field label="Credit limit (Rs)" hint="0 = no limit."><input className="input num" type="number" min="0" value={f.creditLimit} onChange={(e) => set({ creditLimit: e.target.value })} /></Field>
        <Field label="Credit days" hint="Invoices become overdue after this many days."><input className="input num" type="number" min="0" value={f.creditDays} onChange={(e) => set({ creditDays: e.target.value })} /></Field>
        <Field label="Status"><select className="select" value={f.active ? 'a' : 'i'} onChange={(e) => set({ active: e.target.value === 'a' })}><option value="a">Active</option><option value="i">Inactive</option></select></Field>
        <Field label="Notes" span2><textarea className="textarea" value={f.notes} onChange={(e) => set({ notes: e.target.value })} /></Field>
      </div>
    </Modal>
  )
}

export default function CustomersPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const customers = useCustomers()
  const [creating, setCreating] = useState(false)
  const [editing, setEditing] = useState<Customer | null>(null)
  const editable = canEdit(user?.role, 'customers')
  useHotkeys({ 'alt+n': editable ? () => setCreating(true) : undefined })
  if (customers.isLoading) return <Loading />
  const rows = (customers.data ?? []).filter((c) => !c.customer.walkIn)
  const owed = rows.reduce((s, r) => s + Math.max(0, Number(r.balance)), 0)

  return (
    <div>
      <PageHeader kicker="Sales" title="Customers" blurb="Accounts, credit limits and running balances. Open a customer for the complete ledger."
        actions={editable && <button className="btn btn-primary" onClick={() => setCreating(true)}><Icon name="plus" size={16} /> New customer<Kbd>Alt+N</Kbd></button>} />
      <div className="kpi-grid" style={{ marginBottom: 16 }}>
        <Kpi label="Customers" value={rows.length} sub={`${rows.filter((r) => r.customer.type === 'WHOLESALE').length} wholesale · ${rows.filter((r) => r.customer.type === 'RETAIL').length} retail`} icon="users" />
        <Kpi label="Total receivable" value={`Rs ${fmt(owed)}`} sub="owed by customers" icon="inbox" tone="warning" />
      </div>
      <DataTable<CustomerRow>
        searchable searchPlaceholder="Search name, code or phone…" rows={rows} keyOf={(r) => r.customer.id} onRowClick={(r) => navigate(`/customers/${r.customer.id}`)} onEdit={editable ? (r) => setEditing(r.customer) : undefined}
        columns={[
          { label: 'Code', search: (r) => `${r.customer.code} ${r.customer.name} ${r.customer.phone ?? ''}`, render: (r) => <b>{r.customer.code}</b> },
          { label: 'Customer', render: (r) => (<div><div style={{ fontWeight: 650 }}>{r.customer.name}</div><div className="muted" style={{ fontSize: 12 }}>{r.customer.phone ?? r.customer.address ?? ''}</div></div>) },
          { label: 'Type', render: (r) => <Badge tone={r.customer.type === 'WHOLESALE' ? 'primary' : 'info'}>{r.customer.type === 'WHOLESALE' ? 'Wholesale' : 'Retail'}</Badge> },
          { label: 'Credit limit', numeric: true, render: (r) => (r.customer.creditLimit > 0 ? fmt(r.customer.creditLimit) : <span className="muted">None</span>) },
          { label: 'Balance owed', numeric: true, render: (r) => {
            const over = r.customer.creditLimit > 0 && r.balance > r.customer.creditLimit
            return <b className={over ? 'neg' : r.balance > 0 ? '' : 'pos'}>{money(r.balance)}</b>
          } },
          { label: 'Status', render: (r) => (r.customer.active ? <Badge tone="success">Active</Badge> : <Badge>Inactive</Badge>) },
        ]}
        emptyText="No customers yet."
      />
      {creating && <CustomerModal id={null} onClose={() => setCreating(false)} />}
      {editing && <CustomerModal id={editing.id} initial={toCustomerForm(editing)} onClose={() => setEditing(null)} />}
    </div>
  )
}
