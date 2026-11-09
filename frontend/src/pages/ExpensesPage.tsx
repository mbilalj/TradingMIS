import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Api } from '../api/resources'
import type { Expense, ExpenseNature } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit, isOwner } from '../auth/access'
import DataTable from '../components/DataTable'
import DateRange, { presetRange, type Range } from '../components/DateRange'
import Icon from '../components/Icon'
import { Badge, Kbd, Kpi, Loading, PageHeader, Segmented } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, fmtDate, money } from '../lib/format'
import { useAction } from '../lib/useAction'
import ExpenseModal from './ExpenseModal'

export default function ExpensesPage() {
  const { user } = useAuth()
  const [range, setRange] = useState<Range>(presetRange('month'))
  const [nature, setNature] = useState<'' | ExpenseNature>('')
  const [adding, setAdding] = useState(false)
  const list = useQuery({
    queryKey: ['expenses', range, nature],
    queryFn: () => Api.expenses({ from: range.from, to: range.to, nature: nature || undefined }),
  })
  const remove = useAction((id: number) => Api.deleteExpense(id), { ok: 'Payment deleted', invalidate: ['expenses', 'dashboard', 'accounts', 'report'] })
  useHotkeys({ 'alt+n': canEdit(user?.role, 'expenses') ? () => setAdding(true) : undefined })
  if (list.isLoading) return <Loading />

  const rows = list.data ?? []
  const operating = rows.filter((r) => r.nature === 'OPERATING').reduce((s, r) => s + Number(r.amount), 0)
  const nonOperating = rows.filter((r) => r.nature === 'NON_OPERATING').reduce((s, r) => s + Number(r.amount), 0)

  return (
    <div>
      <PageHeader kicker="Payments" title="Expenses & payments"
        blurb="Every payment is tagged. Operating expenses reduce profit; non-operating payments (like customs duty on a container) only reduce cash or bank."
        actions={canEdit(user?.role, 'expenses') && <button className="btn btn-primary" onClick={() => setAdding(true)}><Icon name="plus" size={16} /> Record payment<Kbd>Alt+N</Kbd></button>} />

      <div className="kpi-grid" style={{ marginBottom: 16 }}>
        <Kpi label="Operating expenses" value={`Rs ${fmt(operating)}`} sub="Reduce profit — in the P&L" icon="receipt" tone="danger" />
        <Kpi label="Non-operating payments" value={`Rs ${fmt(nonOperating)}`} sub="Cash / bank only — not in the P&L" icon="truck" tone="info" />
        <Kpi label="Total paid out" value={`Rs ${fmt(operating + nonOperating)}`} sub={`${rows.length} payment${rows.length === 1 ? '' : 's'} in range`} icon="wallet" tone="primary" />
      </div>

      <DataTable<Expense>
        searchable searchPlaceholder="Search category or description…" rows={rows} keyOf={(r) => r.id}
        onDelete={isOwner(user?.role) ? (r) => { if (confirm(`Delete ${r.expenseNo}? The cash/bank balance and books will be reversed.`)) remove.mutate(r.id) } : undefined}
        toolbar={
          <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
            <Segmented<'' | ExpenseNature> value={nature} onChange={setNature} options={[{ value: '', label: 'All' }, { value: 'OPERATING', label: 'Operating' }, { value: 'NON_OPERATING', label: 'Non-operating' }]} />
            <DateRange value={range} onChange={setRange} />
          </div>
        }
        columns={[
          { label: 'Date', render: (r) => fmtDate(r.expenseDate) },
          { label: 'Ref', search: (r) => `${r.expenseNo} ${r.category.name} ${r.description ?? ''} ${r.shipment?.shipmentNo ?? ''}`, render: (r) => <b>{r.expenseNo}</b> },
          { label: 'Nature', render: (r) => (r.nature === 'OPERATING' ? <Badge tone="danger">Operating</Badge> : <Badge tone="info">Non-operating</Badge>) },
          { label: 'Category', render: (r) => r.category.name },
          { label: 'Description', render: (r) => <span className="text-2">{r.description ?? '—'}</span> },
          { label: 'Shipment', render: (r) => (r.shipment ? <Link to={`/shipments/${r.shipment.id}`}>{r.shipment.shipmentNo}</Link> : <span className="muted">—</span>) },
          { label: 'Paid from', render: (r) => r.account.name },
          { label: 'Amount', numeric: true, render: (r) => <b>{money(r.amount)}</b> },
          { label: '', render: (r) => isOwner(user?.role) && <button className="btn btn-ghost btn-sm btn-icon" aria-label="Delete" onClick={() => { if (confirm(`Delete ${r.expenseNo}? The cash/bank balance and books will be reversed.`)) remove.mutate(r.id) }}><Icon name="trash" size={15} /></button> },
        ]}
        emptyText="No payments in this period."
      />
      {adding && <ExpenseModal onClose={() => setAdding(false)} />}
    </div>
  )
}
