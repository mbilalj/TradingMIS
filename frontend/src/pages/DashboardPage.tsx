import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import { useAuth } from '../auth/AuthContext'
import { canEdit, canView } from '../auth/access'
import { compact, fmt, fmtDate, money, qty, titleCase } from '../lib/format'
import BarChart from '../components/BarChart'
import Icon from '../components/Icon'
import { Badge, Card, Kpi, Loading, PageHeader } from '../components/ui'

const TYPE_TONE: Record<string, 'primary' | 'success' | 'warning' | 'info' | 'neutral'> = {
  SALE: 'success', RECEIPT: 'info', SHIPMENT: 'primary', EXPENSE: 'warning', RETURN: 'warning', SUPPLIER_PAYMENT: 'info',
}

export default function DashboardPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const { data, isLoading } = useQuery({ queryKey: ['dashboard'], queryFn: Api.dashboard })
  if (isLoading || !data) return <Loading />

  const hour = new Date().getHours()
  const greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening'
  const finance = canView(user?.role, 'finreports')

  return (
    <div className="section-gap" style={{ gap: 20 }}>
      <PageHeader
        kicker="Overview"
        title={`${greet}, ${user?.fullName.split(' ')[0] ?? ''}`}
        blurb="Where the business stands right now — sales, collections, stock and cash."
        actions={
          <>
            {canEdit(user?.role, 'sales') && <button className="btn btn-primary" onClick={() => navigate('/sales/new')}><Icon name="plus" size={16} /> New sale</button>}
            {canEdit(user?.role, 'receiving') && <button className="btn btn-secondary" onClick={() => navigate('/receiving/new')}><Icon name="truck" size={16} /> Receive stock</button>}
            {canEdit(user?.role, 'receipts') && <button className="btn btn-secondary" onClick={() => navigate('/receipts')}><Icon name="coins" size={16} /> Take payment</button>}
          </>
        }
      />

      <div className="kpi-grid">
        <Kpi label="Today's sales" value={`Rs ${fmt(data.todaySales)}`} sub={`${data.todayInvoices} invoice${data.todayInvoices === 1 ? '' : 's'}`} icon="cart" tone="primary" />
        <Kpi label="Today's collections" value={`Rs ${fmt(data.todayCollections)}`} sub="Cash, bank and receipts" icon="coins" tone="success" />
        {finance && <Kpi label="Today's profit" value={`Rs ${fmt(data.todayProfit)}`} sub="Gross, after returns" icon="trend" tone={data.todayProfit < 0 ? 'danger' : 'success'} />}
        <Kpi label="Monthly sales" value={`Rs ${compact(data.monthlySales)}`} sub="Net of returns" icon="chart" tone="info" />
        {finance && <Kpi label="Monthly profit" value={`Rs ${compact(data.monthlyProfit)}`} sub={`Gross ${compact(data.monthlyGrossProfit)} · expenses ${compact(data.monthlyExpenses)}`} icon="scale" tone={data.monthlyProfit < 0 ? 'danger' : 'success'} />}
      </div>

      <div className="kpi-grid">
        <Kpi label="Total receivables" value={`Rs ${compact(data.totalReceivables)}`} sub={<Link to="/receivables">Customer ageing →</Link>} icon="inbox" tone="warning" />
        {finance && <Kpi label="Total payables" value={`Rs ${compact(data.totalPayables)}`} sub={<Link to="/suppliers">Suppliers →</Link>} icon="building" tone="danger" />}
        <Kpi label="Stock value" value={`Rs ${compact(data.stockValue)}`} sub="At each batch’s own cost" icon="layers" tone="primary" />
        {canView(user?.role, 'cash') && <Kpi label="Cash balance" value={`Rs ${compact(data.cashBalance)}`} sub="Cash in hand" icon="wallet" tone="success" />}
        {canView(user?.role, 'cash') && <Kpi label="Bank balance" value={`Rs ${compact(data.bankBalance)}`} sub={<Link to="/cash">Cash & bank →</Link>} icon="bank" tone="info" />}
      </div>

      <div style={{ display: 'grid', gap: 16, gridTemplateColumns: 'minmax(0, 1.6fr) minmax(0, 1fr)' }}>
        <Card title="Sales — last 14 days" sub="Net sales by day, after returns">
          <BarChart data={data.salesTrend.map((d) => ({ label: d.day.slice(5), value: Number(d.sales) }))} />
        </Card>

        <Card title="Low-stock products" sub={`${data.lowStockCount} at or below minimum`}
          actions={<Link to="/reports/low-stock" style={{ fontSize: 12.5 }}>View all</Link>}>
          {data.lowStock.length === 0 && <div className="muted">Every active product is above its minimum level.</div>}
          <div style={{ display: 'grid', gap: 10 }}>
            {data.lowStock.map((p) => (
              <div key={p.id} style={{ display: 'flex', justifyContent: 'space-between', gap: 10, alignItems: 'center' }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontWeight: 650, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</div>
                  <div className="muted" style={{ fontSize: 12 }}>{p.sku} · min {qty(p.min_stock)}</div>
                </div>
                <Badge tone={Number(p.on_hand) <= 0 ? 'danger' : 'warning'}>{qty(p.on_hand)} {p.unit}</Badge>
              </div>
            ))}
          </div>
        </Card>
      </div>

      <Card title="Recent transactions" sub="Latest postings across stock, sales, payments and expenses" pad={false}>
        <div className="table-scroll">
          <table className="tbl">
            <thead><tr><th>Date</th><th>Type</th><th>Reference</th><th>Details</th><th className="n">Amount</th></tr></thead>
            <tbody>
              {data.recent.length === 0 && <tr><td colSpan={5}><div className="empty">Nothing posted yet — receive stock or make a sale to get started.</div></td></tr>}
              {data.recent.map((r, i) => (
                <tr key={i}>
                  <td>{fmtDate(r.day)}</td>
                  <td><Badge tone={TYPE_TONE[r.type] ?? 'neutral'}>{titleCase(r.type)}</Badge></td>
                  <td><b>{r.ref}</b></td>
                  <td className="text-2">{r.narration}</td>
                  <td className="n">{money(r.amount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  )
}
