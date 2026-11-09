import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import { useAccounts } from '../api/hooks'
import type { AccountType, Voucher } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit, isOwner } from '../auth/access'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import { Badge, Banner, Field, Kbd, Loading, Modal, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmtDate, money, today, titleCase, toNum } from '../lib/format'
import { useAction } from '../lib/useAction'

function AccountModal({ onClose }: { onClose: () => void }) {
  const [name, setName] = useState('')
  const [type, setType] = useState<AccountType>('BANK')
  const [number, setNumber] = useState('')
  const [opening, setOpening] = useState('')
  const save = useAction(() => Api.saveAccount(null, { name, type, accountNumber: number, openingBalance: toNum(opening), active: true }),
    { ok: 'Account created', invalidate: ['accounts', 'report', 'dashboard'], onDone: onClose })
  return (
    <Modal title="New cash / bank account" onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button><button className="btn btn-primary" disabled={!name.trim() || save.isPending} onClick={() => save.mutate(undefined)}>Create account</button></>}>
      <div className="form-grid">
        <Field label="Account name" span2><input className="input" value={name} onChange={(e) => setName(e.target.value)} autoFocus placeholder="e.g. HBL Current Account" /></Field>
        <Field label="Type"><select className="select" value={type} onChange={(e) => setType(e.target.value as AccountType)}><option value="BANK">Bank</option><option value="CASH">Cash</option></select></Field>
        <Field label="Account number"><input className="input" value={number} onChange={(e) => setNumber(e.target.value)} /></Field>
        <Field label="Opening balance (Rs)" span2><input className="input num" type="number" value={opening} onChange={(e) => setOpening(e.target.value)} /></Field>
      </div>
    </Modal>
  )
}

function VoucherModal({ kind, onClose }: { kind: 'RECEIPT' | 'PAYMENT' | 'TRANSFER'; onClose: () => void }) {
  const accounts = useAccounts()
  const [accountId, setAccountId] = useState('')
  const [toAccountId, setToAccountId] = useState('')
  const [purpose, setPurpose] = useState(kind === 'RECEIPT' ? 'OTHER_INCOME' : 'OTHER_EXPENSE')
  const [amount, setAmount] = useState('')
  const [date, setDate] = useState(today())
  const [description, setDescription] = useState('')
  const save = useAction(() => Api.createVoucher({ date, kind, purpose: kind === 'TRANSFER' ? null : purpose, accountId: Number(accountId), toAccountId: toAccountId ? Number(toAccountId) : null, amount: toNum(amount), description }),
    { ok: 'Recorded', invalidate: ['vouchers', 'accounts', 'dashboard', 'report'], onDone: onClose })
  const title = kind === 'RECEIPT' ? 'Cash / bank received' : kind === 'PAYMENT' ? 'Cash / bank paid' : 'Transfer between accounts'
  const list = accounts.data?.filter((a) => a.account.active) ?? []
  return (
    <Modal title={title} onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button><button className="btn btn-primary" disabled={!accountId || toNum(amount) <= 0 || (kind === 'TRANSFER' && !toAccountId) || save.isPending} onClick={() => save.mutate(undefined)}>Save</button></>}>
      <div className="form-grid">
        <Field label={kind === 'TRANSFER' ? 'From account' : 'Account'}>
          <select className="select" value={accountId} onChange={(e) => setAccountId(e.target.value)}><option value="">Select…</option>{list.map((a) => <option key={a.account.id} value={a.account.id}>{a.account.name} ({money(a.balance)})</option>)}</select>
        </Field>
        {kind === 'TRANSFER' && (
          <Field label="To account">
            <select className="select" value={toAccountId} onChange={(e) => setToAccountId(e.target.value)}><option value="">Select…</option>{list.filter((a) => String(a.account.id) !== accountId).map((a) => <option key={a.account.id} value={a.account.id}>{a.account.name}</option>)}</select>
          </Field>
        )}
        {kind === 'RECEIPT' && (
          <Field label="Source"><select className="select" value={purpose} onChange={(e) => setPurpose(e.target.value)}><option value="OTHER_INCOME">Other income</option><option value="CAPITAL_INTRODUCED">Owner capital introduced</option></select></Field>
        )}
        {kind === 'PAYMENT' && (
          <Field label="Purpose"><select className="select" value={purpose} onChange={(e) => setPurpose(e.target.value)}><option value="OTHER_EXPENSE">Other expense (reduces profit)</option><option value="DRAWINGS">Owner drawings</option></select></Field>
        )}
        <Field label="Date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
        <Field label="Amount (Rs)"><input className="input num" type="number" min="0" value={amount} onChange={(e) => setAmount(e.target.value)} autoFocus /></Field>
        <Field label="Description" span2><input className="input" value={description} onChange={(e) => setDescription(e.target.value)} /></Field>
      </div>
      {kind === 'PAYMENT' && <div style={{ marginTop: 14 }}><Banner icon="info">Supplier payments, customer receipts, expenses and shipment payments have their own screens — use this only for other movements.</Banner></div>}
    </Modal>
  )
}

export default function CashPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const accounts = useAccounts()
  const vouchers = useQuery({ queryKey: ['vouchers'], queryFn: Api.vouchers })
  const [modal, setModal] = useState<'account' | 'RECEIPT' | 'PAYMENT' | 'TRANSFER' | null>(null)
  const remove = useAction((id: number) => Api.deleteVoucher(id), { ok: 'Voucher deleted', invalidate: ['vouchers', 'accounts', 'dashboard', 'report'] })
  const editable = canEdit(user?.role, 'cash')
  useHotkeys({
    'alt+n': editable ? () => setModal('account') : undefined, 'alt+r': editable ? () => setModal('RECEIPT') : undefined,
    'alt+p': editable ? () => setModal('PAYMENT') : undefined, 'alt+t': editable ? () => setModal('TRANSFER') : undefined,
  })
  if (accounts.isLoading) return <Loading />
  const list = accounts.data ?? []
  const cash = list.filter((a) => a.account.type === 'CASH').reduce((s, a) => s + Number(a.balance), 0)
  const bank = list.filter((a) => a.account.type === 'BANK').reduce((s, a) => s + Number(a.balance), 0)

  return (
    <div className="section-gap" style={{ gap: 18 }}>
      <PageHeader kicker="Payments" title="Cash & bank" blurb="Every rupee in and out. Sales, receipts, expenses, shipment payments and transfers all land here automatically."
        actions={editable && <>
          <button className="btn btn-secondary" onClick={() => setModal('RECEIPT')}>Money in<Kbd>Alt+R</Kbd></button>
          <button className="btn btn-secondary" onClick={() => setModal('PAYMENT')}>Money out<Kbd>Alt+P</Kbd></button>
          <button className="btn btn-secondary" onClick={() => setModal('TRANSFER')}>Transfer<Kbd>Alt+T</Kbd></button>
          <button className="btn btn-primary" onClick={() => setModal('account')}><Icon name="plus" size={16} /> New account<Kbd>Alt+N</Kbd></button>
        </>} />

      <div className="kpi-grid">
        <div className="card kpi" style={{ background: 'linear-gradient(135deg,#1f3fb8,#3e63f0)', color: '#fff', border: 0 }}>
          <div><div className="lbl" style={{ color: '#c8d4ff' }}>Total cash + bank</div><div className="kpi-value" style={{ fontSize: 28 }}>Rs {money(cash + bank)}</div>
            <div style={{ color: '#c8d4ff', fontSize: 12.5, marginTop: 4 }}>Cash Rs {money(cash)} · Bank Rs {money(bank)}</div></div>
        </div>
        {list.map((a) => (
          <div key={a.account.id} className="card kpi" style={{ alignItems: 'center' }}>
            <div className={`kpi-icon ${a.account.type === 'CASH' ? 'success' : 'info'}`}><Icon name={a.account.type === 'CASH' ? 'wallet' : 'bank'} size={20} /></div>
            <div style={{ minWidth: 0, flex: 1 }}>
              <div className="lbl">{a.account.type === 'CASH' ? 'Cash' : 'Bank'}{!a.account.active && ' · inactive'}</div>
              <div style={{ fontWeight: 650 }}>{a.account.name}</div>
              <div className="kpi-value" style={{ fontSize: 20 }}>Rs {money(a.balance)}</div>
              <button className="btn btn-ghost btn-sm" style={{ padding: '0 0', height: 22 }} onClick={() => navigate(`/reports/${a.account.type === 'CASH' ? 'cash-book' : 'bank-book'}?id=${a.account.id}`)}>Open {a.account.type === 'CASH' ? 'cash' : 'bank'} book →</button>
            </div>
          </div>
        ))}
      </div>

      <div className="card-title">Cash & bank vouchers</div>
      <DataTable<Voucher>
        searchable searchPlaceholder="Search voucher or description…" rows={vouchers.data ?? []} keyOf={(v) => v.id}
        onDelete={isOwner(user?.role) ? (v) => { if (confirm(`Delete ${v.voucherNo}?`)) remove.mutate(v.id) } : undefined}
        columns={[
          { label: 'Voucher', search: (v) => `${v.voucherNo} ${v.description ?? ''} ${v.account.name}`, render: (v) => <b>{v.voucherNo}</b> },
          { label: 'Date', render: (v) => fmtDate(v.voucherDate) },
          { label: 'Type', render: (v) => <Badge tone={v.kind === 'RECEIPT' ? 'success' : v.kind === 'PAYMENT' ? 'danger' : 'info'}>{v.kind === 'RECEIPT' ? 'Money in' : v.kind === 'PAYMENT' ? 'Money out' : 'Transfer'}</Badge> },
          { label: 'Account', render: (v) => (v.toAccount ? `${v.account.name} → ${v.toAccount.name}` : v.account.name) },
          { label: 'Purpose', render: (v) => (v.purpose ? titleCase(v.purpose) : '—') },
          { label: 'Description', render: (v) => <span className="text-2">{v.description ?? '—'}</span> },
          { label: 'Amount', numeric: true, render: (v) => <b>{money(v.amount)}</b> },
          { label: '', render: (v) => isOwner(user?.role) && <button className="btn btn-ghost btn-sm btn-icon" aria-label="Delete" onClick={() => { if (confirm(`Delete ${v.voucherNo}?`)) remove.mutate(v.id) }}><Icon name="trash" size={15} /></button> },
        ]}
        emptyText="No manual vouchers yet."
      />
      {modal === 'account' && <AccountModal onClose={() => setModal(null)} />}
      {(modal === 'RECEIPT' || modal === 'PAYMENT' || modal === 'TRANSFER') && <VoucherModal kind={modal} onClose={() => setModal(null)} />}
    </div>
  )
}
