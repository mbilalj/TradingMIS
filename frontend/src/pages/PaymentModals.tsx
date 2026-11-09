import { useState } from 'react'
import { Api } from '../api/resources'
import { useAccounts, useCustomers, useSuppliers } from '../api/hooks'
import { Banner, Field, Modal } from '../components/ui'
import { money, today, toNum } from '../lib/format'
import { useAction } from '../lib/useAction'
import { METHODS } from './ExpenseModal'

function AccountSelect({ method, value, onChange }: { method: string; value: string; onChange: (v: string) => void }) {
  const accounts = useAccounts()
  return (
    <select className="select" value={value} onChange={(e) => onChange(e.target.value)}>
      <option value="">{method === 'CASH' ? 'Default cash account' : 'Default bank account'}</option>
      {accounts.data?.filter((a) => a.account.active).map((a) => <option key={a.account.id} value={a.account.id}>{a.account.name}</option>)}
    </select>
  )
}

/** Record money received from a customer; it settles their oldest unpaid invoices first. */
export function ReceivePaymentModal({ customerId, onClose }: { customerId?: number; onClose: () => void }) {
  const customers = useCustomers()
  const [cid, setCid] = useState(customerId ? String(customerId) : '')
  const [date, setDate] = useState(today())
  const [amount, setAmount] = useState('')
  const [method, setMethod] = useState('CASH')
  const [accountId, setAccountId] = useState('')
  const [reference, setReference] = useState('')
  const [notes, setNotes] = useState('')
  const row = customers.data?.find((c) => String(c.customer.id) === cid)

  const save = useAction(
    () => Api.createReceipt({ customerId: Number(cid), date, amount: toNum(amount), method, accountId: accountId ? Number(accountId) : null, reference, notes }),
    { ok: 'Payment recorded', invalidate: ['receipts', 'sales', 'customers', 'dashboard', 'accounts', 'report'], onDone: onClose },
  )

  return (
    <Modal title="Receive customer payment" onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary" disabled={save.isPending || !cid || toNum(amount) <= 0} onClick={() => save.mutate(undefined)}>{save.isPending ? 'Saving…' : 'Record payment'}</button></>}>
      <div className="form-grid">
        <Field label="Customer" span2>
          <select className="select" value={cid} onChange={(e) => setCid(e.target.value)} disabled={!!customerId}>
            <option value="">Select customer…</option>
            {customers.data?.filter((c) => !c.customer.walkIn).map((c) => <option key={c.customer.id} value={c.customer.id}>{c.customer.name}</option>)}
          </select>
        </Field>
        {row && <div className="span-2"><Banner icon="info">Currently owes <b>Rs {money(row.balance)}</b>{toNum(amount) > 0 && <> · after this payment <b>Rs {money(row.balance - toNum(amount))}</b></>}.</Banner></div>}
        <Field label="Date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
        <Field label="Amount received (Rs)"><input className="input num" type="number" min="0" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus /></Field>
        <Field label="Payment method"><select className="select" value={method} onChange={(e) => setMethod(e.target.value)}>{METHODS.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}</select></Field>
        <Field label="Received into"><AccountSelect method={method} value={accountId} onChange={setAccountId} /></Field>
        <Field label="Reference / cheque number" span2><input className="input" value={reference} onChange={(e) => setReference(e.target.value)} /></Field>
        <Field label="Notes" span2><input className="input" value={notes} onChange={(e) => setNotes(e.target.value)} /></Field>
      </div>
    </Modal>
  )
}

/** Pay money out to a supplier against what is owed to them. */
export function PaySupplierModal({ supplierId, onClose }: { supplierId?: number; onClose: () => void }) {
  const suppliers = useSuppliers()
  const [sid, setSid] = useState(supplierId ? String(supplierId) : '')
  const [date, setDate] = useState(today())
  const [amount, setAmount] = useState('')
  const [method, setMethod] = useState('BANK_TRANSFER')
  const [accountId, setAccountId] = useState('')
  const [reference, setReference] = useState('')
  const [notes, setNotes] = useState('')
  const row = suppliers.data?.find((s) => String(s.supplier.id) === sid)

  const save = useAction(
    () => Api.createSupplierPayment({ supplierId: Number(sid), date, amount: toNum(amount), method, accountId: accountId ? Number(accountId) : null, reference, notes }),
    { ok: 'Supplier payment recorded', invalidate: ['supplier-payments', 'suppliers', 'dashboard', 'accounts', 'report'], onDone: onClose },
  )

  return (
    <Modal title="Pay supplier" onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary" disabled={save.isPending || !sid || toNum(amount) <= 0} onClick={() => save.mutate(undefined)}>{save.isPending ? 'Saving…' : 'Record payment'}</button></>}>
      <div className="form-grid">
        <Field label="Supplier" span2>
          <select className="select" value={sid} onChange={(e) => setSid(e.target.value)} disabled={!!supplierId}>
            <option value="">Select supplier…</option>
            {suppliers.data?.map((s) => <option key={s.supplier.id} value={s.supplier.id}>{s.supplier.name}</option>)}
          </select>
        </Field>
        {row && <div className="span-2"><Banner icon="info">You currently owe <b>Rs {money(row.balance)}</b> to {row.supplier.name}.</Banner></div>}
        <Field label="Date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
        <Field label="Amount paid (Rs)"><input className="input num" type="number" min="0" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus /></Field>
        <Field label="Payment method"><select className="select" value={method} onChange={(e) => setMethod(e.target.value)}>{METHODS.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}</select></Field>
        <Field label="Paid from"><AccountSelect method={method} value={accountId} onChange={setAccountId} /></Field>
        <Field label="Reference / cheque number" span2><input className="input" value={reference} onChange={(e) => setReference(e.target.value)} /></Field>
        <Field label="Notes" span2><input className="input" value={notes} onChange={(e) => setNotes(e.target.value)} /></Field>
      </div>
    </Modal>
  )
}

/** Manual +/- correction to a customer or supplier balance; always needs a reason. */
export function AdjustmentModal({ type, partyId, name, onClose }: { type: 'CUSTOMER' | 'SUPPLIER'; partyId: number; name: string; onClose: () => void }) {
  const [date, setDate] = useState(today())
  const [direction, setDirection] = useState<'up' | 'down'>('down')
  const [amount, setAmount] = useState('')
  const [reason, setReason] = useState('')
  const save = useAction(
    () => Api.createPartyAdjustment({ partyType: type, partyId, date, amount: (direction === 'up' ? 1 : -1) * toNum(amount), reason }),
    { ok: 'Adjustment posted', onDone: onClose },
  )
  const upLabel = type === 'CUSTOMER' ? 'Increase what they owe me' : 'Increase what I owe them'
  const downLabel = type === 'CUSTOMER' ? 'Reduce what they owe me (discount / write-off)' : 'Reduce what I owe them'
  return (
    <Modal title={`Balance adjustment — ${name}`} onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary" disabled={save.isPending || toNum(amount) <= 0 || !reason.trim()} onClick={() => save.mutate(undefined)}>Post adjustment</button></>}>
      <div className="form-grid">
        <Field label="Date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
        <Field label="Amount (Rs)"><input className="input num" type="number" min="0" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus /></Field>
        <Field label="Effect" span2>
          <select className="select" value={direction} onChange={(e) => setDirection(e.target.value as 'up' | 'down')}>
            <option value="down">{downLabel}</option><option value="up">{upLabel}</option>
          </select>
        </Field>
        <Field label="Reason (required)" span2><input className="input" value={reason} onChange={(e) => setReason(e.target.value)} /></Field>
      </div>
    </Modal>
  )
}
