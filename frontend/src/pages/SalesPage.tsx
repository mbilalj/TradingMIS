import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import type { Sale, SaleType } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit, canView } from '../auth/access'
import DataTable from '../components/DataTable'
import DateRange, { presetRange, type Range } from '../components/DateRange'
import Icon from '../components/Icon'
import { Badge, Kbd, Kpi, Loading, PageHeader, Segmented } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, fmtDate, money } from '../lib/format'

export function paymentBadge(s: Sale) {
  const out = Math.max(0, Number(s.outstanding))
  if (Number(s.total) <= 0) return <Badge>—</Badge>
  if (out <= 0.004) return <Badge tone="success">Paid</Badge>
  if (Number(s.paidAmount) > 0) return <Badge tone="warning">Partly paid</Badge>
  return <Badge tone="danger">Unpaid</Badge>
}

export default function SalesPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [range, setRange] = useState<Range>(presetRange('month'))
  const [type, setType] = useState<'' | SaleType>('')
  const showProfit = canView(user?.role, 'finreports') || user?.role === 'SALES_OFFICER'
  const { data, isLoading } = useQuery({ queryKey: ['sales', range, type], queryFn: () => Api.sales({ from: range.from, to: range.to, type: type || undefined }) })
  useHotkeys({ 'alt+n': canEdit(user?.role, 'sales') ? () => navigate('/sales/new') : undefined })
  if (isLoading) return <Loading />

  const rows = data ?? []
  const total = rows.reduce((s, r) => s + Number(r.total), 0)
  const outstanding = rows.reduce((s, r) => s + Math.max(0, Number(r.outstanding)), 0)
  const profit = rows.reduce((s, r) => s + Number(r.profit), 0)

  return (
    <div>
      <PageHeader kicker="Sales" title="Sales & invoices" blurb="Wholesale and retail invoices in one place. Open any invoice to print it, save it as PDF or process a return."
        actions={canEdit(user?.role, 'sales') && <button className="btn btn-primary" onClick={() => navigate('/sales/new')}><Icon name="plus" size={16} /> New sale<Kbd>Alt+N</Kbd></button>} />

      <div className="kpi-grid" style={{ marginBottom: 16 }}>
        <Kpi label="Invoiced" value={`Rs ${fmt(total)}`} sub={`${rows.length} invoices`} icon="cart" />
        <Kpi label="Still to collect" value={`Rs ${fmt(outstanding)}`} sub="on these invoices" icon="inbox" tone="warning" />
        {showProfit && <Kpi label="Gross profit" value={`Rs ${fmt(profit)}`} sub="after returns, at batch cost" icon="trend" tone="success" />}
      </div>

      <DataTable<Sale>
        searchable searchPlaceholder="Search invoice number or customer…" rows={rows} keyOf={(r) => r.id} onRowClick={(r) => navigate(`/sales/${r.id}`)}
        toolbar={<div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
          <Segmented<'' | SaleType> value={type} onChange={setType} options={[{ value: '', label: 'All' }, { value: 'RETAIL', label: 'Retail' }, { value: 'WHOLESALE', label: 'Wholesale' }]} />
          <DateRange value={range} onChange={setRange} />
        </div>}
        columns={[
          { label: 'Invoice', search: (r) => `${r.invoiceNo} ${r.customer.name}`, render: (r) => <b>{r.invoiceNo}</b> },
          { label: 'Date', render: (r) => fmtDate(r.saleDate) },
          { label: 'Customer', render: (r) => r.customer.walkIn ? <span className="muted">Walk-in</span> : r.customer.name },
          { label: 'Type', render: (r) => <Badge tone={r.type === 'WHOLESALE' ? 'primary' : 'info'}>{r.type === 'WHOLESALE' ? 'Wholesale' : 'Retail'}</Badge> },
          { label: 'Total', numeric: true, render: (r) => money(r.total) },
          { label: 'Paid', numeric: true, render: (r) => money(r.paidAmount) },
          { label: 'Balance', numeric: true, render: (r) => <span className={Number(r.outstanding) > 0.004 ? 'neg' : ''}>{money(Math.max(0, Number(r.outstanding)))}</span> },
          ...(showProfit ? [{ label: 'Profit', numeric: true, render: (r: Sale) => <span className={Number(r.profit) < 0 ? 'neg' : 'pos'}>{money(r.profit)}</span> }] : []),
          { label: 'Status', render: (r) => paymentBadge(r) },
        ]}
        emptyText="No invoices in this period."
      />
    </div>
  )
}
