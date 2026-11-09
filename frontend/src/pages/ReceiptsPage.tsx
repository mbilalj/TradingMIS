import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Api } from '../api/resources'
import type { Receipt } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import ReportView from '../components/ReportView'
import { Kbd, Kpi, Loading, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, fmtDate, money, titleCase } from '../lib/format'
import { ReceivePaymentModal } from './PaymentModals'

export function ReceiptsPage() {
  const { user } = useAuth()
  const [adding, setAdding] = useState(false)
  useHotkeys({ 'alt+n': canEdit(user?.role, 'receipts') ? () => setAdding(true) : undefined })
  const { data, isLoading } = useQuery({ queryKey: ['receipts'], queryFn: Api.receipts })
  if (isLoading) return <Loading />
  const rows = data ?? []
  const total = rows.reduce((s, r) => s + Number(r.amount), 0)

  return (
    <div>
      <PageHeader kicker="Payments" title="Customer payments" blurb="Money received against customer accounts. A payment settles the oldest unpaid invoices first and the customer’s balance updates immediately."
        actions={canEdit(user?.role, 'receipts') && <button className="btn btn-primary" onClick={() => setAdding(true)}><Icon name="plus" size={16} /> Receive payment<Kbd>Alt+N</Kbd></button>} />
      <div className="kpi-grid" style={{ marginBottom: 16 }}>
        <Kpi label="Receipts shown" value={rows.length} sub="most recent 500" icon="inbox" />
        <Kpi label="Total received" value={`Rs ${fmt(total)}`} icon="coins" tone="success" />
      </div>
      <DataTable<Receipt>
        searchable searchPlaceholder="Search receipt, customer or cheque number…" rows={rows} keyOf={(r) => r.id}
        columns={[
          { label: 'Receipt', search: (r) => `${r.receiptNo} ${r.customer.name} ${r.reference ?? ''}`, render: (r) => <b>{r.receiptNo}</b> },
          { label: 'Date', render: (r) => fmtDate(r.receiptDate) },
          { label: 'Customer', render: (r) => <Link to={`/customers/${r.customer.id}`}>{r.customer.name}</Link> },
          { label: 'Method', render: (r) => (r.method ? titleCase(r.method) : '—') },
          { label: 'Reference', render: (r) => r.reference ?? <span className="muted">—</span> },
          { label: 'Into account', render: (r) => r.account.name },
          { label: 'Amount', numeric: true, render: (r) => <b>{money(r.amount)}</b> },
        ]}
        emptyText="No customer payments yet."
      />
      {adding && <ReceivePaymentModal onClose={() => setAdding(false)} />}
    </div>
  )
}

export function ReceivablesPage() {
  const { user } = useAuth()
  const [adding, setAdding] = useState(false)
  useHotkeys({ 'alt+n': canEdit(user?.role, 'receipts') ? () => setAdding(true) : undefined })
  return (
    <div>
      <PageHeader kicker="Payments" title="Receivables & overdue" blurb="Who owes you, how much of it is overdue, and for how long. Overdue is measured from each invoice’s due date (invoice date + the customer’s credit days)."
        actions={canEdit(user?.role, 'receipts') && <button className="btn btn-primary" onClick={() => setAdding(true)}><Icon name="coins" size={16} /> Receive payment<Kbd>Alt+N</Kbd></button>} />
      <ReportView code="receivables" embedded />
      <div style={{ height: 22 }} />
      <div className="card-title" style={{ marginBottom: 10 }}>Overdue invoices</div>
      <ReportView code="overdue" embedded />
      {adding && <ReceivePaymentModal onClose={() => setAdding(false)} />}
    </div>
  )
}
