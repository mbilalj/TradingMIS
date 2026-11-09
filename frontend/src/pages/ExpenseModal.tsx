import { useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Api } from '../api/resources'
import { useAccounts, useCategories } from '../api/hooks'
import type { ExpenseNature } from '../api/types'
import Icon from '../components/Icon'
import { Banner, Field, Modal, Segmented } from '../components/ui'
import { today, toNum } from '../lib/format'
import { useAction } from '../lib/useAction'

export const METHODS = [
  { value: 'CASH', label: 'Cash' },
  { value: 'BANK_TRANSFER', label: 'Bank transfer' },
  { value: 'CHEQUE', label: 'Cheque' },
  { value: 'ONLINE', label: 'Online / card' },
]

export default function ExpenseModal({ onClose, presetNature = 'OPERATING', presetShipmentId }: {
  onClose: () => void; presetNature?: ExpenseNature; presetShipmentId?: number
}) {
  const categories = useCategories()
  const accounts = useAccounts()
  const shipments = useQuery({ queryKey: ['shipments'], queryFn: Api.shipments })
  const file = useRef<HTMLInputElement>(null)

  const [nature, setNature] = useState<ExpenseNature>(presetNature)
  const [date, setDate] = useState(today())
  const [categoryId, setCategoryId] = useState('')
  const [amount, setAmount] = useState('')
  const [accountId, setAccountId] = useState('')
  const [method, setMethod] = useState('CASH')
  const [shipmentId, setShipmentId] = useState(presetShipmentId ? String(presetShipmentId) : '')
  const [description, setDescription] = useState('')
  const [doc, setDoc] = useState<File | null>(null)
  const [newCat, setNewCat] = useState('')

  const cats = (categories.data ?? []).filter((c) => c.nature === nature && c.active)
  const addCat = useAction(() => Api.createCategory({ name: newCat, nature }), {
    ok: 'Category added', invalidate: ['categories'], onDone: (c) => { setCategoryId(String(c.id)); setNewCat('') },
  })
  const save = useAction(
    async () => {
      const e = await Api.createExpense({
        date, nature, categoryId: Number(categoryId), amount: toNum(amount), accountId: accountId ? Number(accountId) : null,
        method, shipmentId: nature === 'NON_OPERATING' && shipmentId ? Number(shipmentId) : null, description,
      })
      if (doc) await Api.upload('EXPENSE', e.id, doc)
      return e
    },
    { ok: nature === 'OPERATING' ? 'Expense recorded' : 'Payment recorded', invalidate: ['expenses', 'dashboard', 'accounts', 'report', 'shipments'], onDone: onClose },
  )

  return (
    <Modal title="Record a payment" onClose={onClose}
      footer={<>
        <button className="btn btn-ghost" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary" disabled={save.isPending || !categoryId || toNum(amount) <= 0} onClick={() => save.mutate()}>{save.isPending ? 'Saving…' : 'Save payment'}</button>
      </>}>
      <div style={{ display: 'grid', gap: 16 }}>
        <div>
          <div className="lbl" style={{ marginBottom: 6 }}>What kind of payment is this?</div>
          <Segmented<ExpenseNature> value={nature} onChange={(n) => { setNature(n); setCategoryId('') }}
            options={[{ value: 'OPERATING', label: 'Operating expense' }, { value: 'NON_OPERATING', label: 'Non-operating / shipment payment' }]} />
          <div style={{ marginTop: 10 }}>
            {nature === 'OPERATING'
              ? <Banner icon="trend" tone="info"><b>Reduces profit.</b> Salaries, electricity, rent, transport and other running costs. Appears in the Profit &amp; Loss.</Banner>
              : <Banner icon="info" tone="warn"><b>Does not affect profit.</b> Customs duty and other costs tied to inventory or a new container. Only the cash/bank balance goes down; it stays out of the Profit &amp; Loss.</Banner>}
          </div>
        </div>

        <div className="form-grid">
          <Field label="Date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
          <Field label="Amount (Rs)"><input className="input num" type="number" min="0" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus /></Field>
          <Field label="Category">
            <select className="select" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
              <option value="">Select category…</option>
              {cats.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </Field>
          <Field label="Or add a new category">
            <div style={{ display: 'flex', gap: 6 }}>
              <input className="input" value={newCat} onChange={(e) => setNewCat(e.target.value)} placeholder="e.g. Fuel" />
              <button className="btn btn-secondary" disabled={!newCat.trim() || addCat.isPending} onClick={() => addCat.mutate(undefined)}>Add</button>
            </div>
          </Field>
          <Field label="Paid from">
            <select className="select" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
              <option value="">{method === 'CASH' ? 'Default cash account' : 'Default bank account'}</option>
              {accounts.data?.filter((a) => a.account.active).map((a) => <option key={a.account.id} value={a.account.id}>{a.account.name}</option>)}
            </select>
          </Field>
          <Field label="Payment method">
            <select className="select" value={method} onChange={(e) => setMethod(e.target.value)}>{METHODS.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}</select>
          </Field>
          {nature === 'NON_OPERATING' && (
            <Field label="Link to shipment / batch" span2 hint="Keeps customs and clearing payments on the record of the container they belong to.">
              <select className="select" value={shipmentId} onChange={(e) => setShipmentId(e.target.value)}>
                <option value="">Not linked to a shipment</option>
                {shipments.data?.map((s) => <option key={s.id} value={s.id}>{s.containerNo ? `${s.containerNo} · ` : ''}{s.shipmentNo} · {s.supplier.name}</option>)}
              </select>
            </Field>
          )}
          <Field label="Description" span2><input className="input" value={description} onChange={(e) => setDescription(e.target.value)} /></Field>
        </div>

        <div>
          <input ref={file} type="file" hidden onChange={(e) => setDoc(e.target.files?.[0] ?? null)} />
          <button className="btn btn-secondary btn-sm" onClick={() => file.current?.click()}><Icon name="clip" size={15} /> {doc ? doc.name : 'Attach bill / voucher (optional)'}</button>
        </div>
      </div>
    </Modal>
  )
}
