import { Link, Navigate, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { canView } from '../auth/access'
import Icon, { type IconName } from '../components/Icon'
import ReportView from '../components/ReportView'
import { PageHeader } from '../components/ui'
import { REPORT_GROUPS, REPORTS, reportDef, type ReportGroup } from '../lib/reports'

const GROUP_ICON: Record<ReportGroup, IconName> = { Sales: 'cart', Inventory: 'layers', Customers: 'users', Suppliers: 'building', Financial: 'scale' }
const GROUP_BLURB: Record<ReportGroup, string> = {
  Sales: 'Daily and monthly sales, by customer, product and invoice.',
  Inventory: 'Stock levels, valuation, batches and every movement.',
  Customers: 'Ledgers, balances, receivables and overdue amounts.',
  Suppliers: 'Supplier ledgers, payables and payment history.',
  Financial: 'Profit & loss, cash book, bank book, trial balance and balance sheet.',
}

export function ReportsHub() {
  const { user } = useAuth()
  const allowed = (fin?: boolean) => canView(user?.role, fin ? 'finreports' : 'reports')

  return (
    <div>
      <PageHeader kicker="Insights" title="Reports" blurb="Pick a report, choose the dates, then print it, save it as PDF or export it to Excel." />
      <div className="section-gap" style={{ gap: 22 }}>
        {REPORT_GROUPS.map((g) => {
          const list = REPORTS.filter((r) => r.group === g && allowed(r.fin))
          if (!list.length) return null
          return (
            <section key={g}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
                <div className="kpi-icon primary" style={{ width: 34, height: 34 }}><Icon name={GROUP_ICON[g]} size={18} /></div>
                <div><div className="card-title" style={{ fontSize: 16 }}>{g}</div><div className="card-sub">{GROUP_BLURB[g]}</div></div>
              </div>
              <div style={{ display: 'grid', gap: 12, gridTemplateColumns: 'repeat(auto-fill, minmax(290px, 1fr))' }}>
                {list.map((r) => (
                  <Link key={r.code} to={`/reports/${r.code}`} className="card" style={{ padding: '14px 16px', textDecoration: 'none', color: 'inherit', display: 'block' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 8 }}>
                      <div style={{ fontWeight: 680 }}>{r.title}</div><Icon name="arrow" size={16} className="muted" />
                    </div>
                    <div className="muted" style={{ fontSize: 12.5, marginTop: 4 }}>{r.blurb}</div>
                  </Link>
                ))}
              </div>
            </section>
          )
        })}
      </div>
    </div>
  )
}

export function ReportPage() {
  const { code = '' } = useParams()
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const def = reportDef(code)
  if (!def) return <Navigate to="/reports" replace />
  if (!canView(user?.role, def.fin ? 'finreports' : 'reports')) return <div className="empty">You don’t have access to this report.</div>
  const id = params.get('id')

  return (
    <div>
      <PageHeader kicker={def.group + ' report'} title={def.title} blurb={def.blurb}
        actions={<button className="btn btn-ghost" onClick={() => navigate('/reports')}>All reports</button>} />
      <ReportView key={code + (id ?? '')} code={code} initialId={id ? Number(id) : undefined} />
    </div>
  )
}
