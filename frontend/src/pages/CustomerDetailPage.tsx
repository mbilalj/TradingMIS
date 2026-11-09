import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Api } from '../api/resources'
import { useCustomers } from '../api/hooks'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import Icon from '../components/Icon'
import ReportView from '../components/ReportView'
import { Badge, Kbd, Kpi, Loading, PageHeader, Tabs } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, fmtDate, money } from '../lib/format'
import { CustomerModal, toCustomerForm } from './CustomersPage'
import { AdjustmentModal, ReceivePaymentModal } from './PaymentModals'
import { paymentBadge } from './SalesPage'

type Tab = 'ledger' | 'invoices' | 'payments'

export default function CustomerDetailPage() {
  const { id } = useParams()
  const cid = Number(id)
  const { user } = useAuth()
  const navigate = useNavigate()
  const customers = useCustomers()
  const [tab, setTab] = useState<Tab>('ledger')
  const [modal, setModal] = useState<'pay' | 'adj' | 'edit' | null>(null)
  useHotkeys({
    'alt+e': canEdit(user?.role, 'customers') ? () => setModal('edit') : undefined,
    'alt+p': canEdit(user?.role, 'receipts') ? () => setModal('pay') : undefined,
    'alt+a': canEdit(user?.role, 'receipts') ? () => setModal('adj') : undefined,
  })
  const sales = useQuery({ queryKey: ['sales', 'customer', cid], queryFn: () => Api.sales({ customerId: String(cid) }), enabled: tab === 'invoices' })
  const overdue = useQuery({ queryKey: ['report', 'overdue', cid], queryFn: () => Api.report('overdue', { id: String(cid) }) })
  const row = customers.data?.find((c) => c.customer.id === cid)
  if (customers.isLoading) return <Loading />
  if (!row) return <div className="empty">Customer not found. <Link to="/customers">Back to customers</Link></div>
  const c = row.customer
  const overdueTotal = Number(overdue.data?.totals?.outstanding ?? 0)
  const available = c.creditLimit > 0 ? c.creditLimit - row.balance : null
  const editable = canEdit(user?.role, 'customers')

  return (
    <div className="section-gap" style={{ gap: 18 }}>
      <PageHeader kicker="Customer account" title={c.name}
        blurb={[c.code, c.type === 'WHOLESALE' ? 'Wholesale' : 'Retail', c.phone, c.address].filter(Boolean).join(' · ')}
        actions={<>
          <button className="btn btn-ghost" onClick={() => navigate('/customers')}>Back</button>
          {editable && <button className="btn btn-secondary" onClick={() => setModal('edit')}><Icon name="edit" size={16} /> Edit<Kbd>Alt+E</Kbd></button>}
          {canEdit(user?.role, 'receipts') && <button className="btn btn-secondary" onClick={() => setModal('adj')}><Icon name="sliders" size={16} /> Adjustment<Kbd>Alt+A</Kbd></button>}
          {canEdit(user?.role, 'receipts') && <button className="btn btn-primary" onClick={() => setModal('pay')}><Icon name="coins" size={16} /> Receive payment<Kbd>Alt+P</Kbd></button>}
        </>} />

      <div className="kpi-grid">
        <Kpi label="Owes you" value={`Rs ${money(row.balance)}`} sub={row.balance < 0 ? 'Customer is in credit' : 'Current closing balance'} icon="inbox" tone={row.balance > 0 ? 'warning' : 'success'} />
        <Kpi label="Overdue" value={`Rs ${money(overdueTotal)}`} sub={`Invoices unpaid after ${c.creditDays} days`} icon="alert" tone={overdueTotal > 0 ? 'danger' : 'success'} />
        <Kpi label="Credit limit" value={c.creditLimit > 0 ? `Rs ${fmt(c.creditLimit)}` : 'No limit'} sub={available != null ? (available >= 0 ? `Rs ${fmt(available)} available` : <span className="neg">Over limit by Rs {fmt(-available)}</span>) : undefined} icon="card" tone="info" />
        <Kpi label="Opening balance" value={`Rs ${money(c.openingBalance)}`} sub={c.active ? 'Active account' : 'Inactive'} icon="file" />
      </div>

      <Tabs<Tab> value={tab} onChange={setTab} options={[{ value: 'ledger', label: 'Ledger' }, { value: 'invoices', label: 'Invoices' }, { value: 'payments', label: 'Payment history' }]} />

      {tab === 'ledger' && <ReportView code="customer-ledger" initialId={cid} lockPick embedded />}
      {tab === 'payments' && <ReportView code="customer-payment-history" initialId={cid} lockPick embedded />}
      {tab === 'invoices' && (
        <div className="card" style={{ overflow: 'hidden' }}>
          <table className="tbl">
            <thead><tr><th>Invoice</th><th>Date</th><th>Type</th><th className="n">Total</th><th className="n">Paid</th><th className="n">Balance</th><th>Status</th></tr></thead>
            <tbody>
              {(sales.data ?? []).length === 0 && <tr><td colSpan={7}><div className="empty">No invoices yet.</div></td></tr>}
              {(sales.data ?? []).map((s) => (
                <tr key={s.id} className="clickable" onClick={() => navigate(`/sales/${s.id}`)}>
                  <td><b>{s.invoiceNo}</b></td><td>{fmtDate(s.saleDate)}</td><td><Badge tone={s.type === 'WHOLESALE' ? 'primary' : 'info'}>{s.type === 'WHOLESALE' ? 'Wholesale' : 'Retail'}</Badge></td>
                  <td className="n">{money(s.total)}</td><td className="n">{money(s.paidAmount)}</td><td className="n">{money(Math.max(0, Number(s.outstanding)))}</td><td>{paymentBadge(s)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal === 'pay' && <ReceivePaymentModal customerId={cid} onClose={() => setModal(null)} />}
      {modal === 'adj' && <AdjustmentModal type="CUSTOMER" partyId={cid} name={c.name} onClose={() => setModal(null)} />}
      {modal === 'edit' && <CustomerModal id={cid} initial={toCustomerForm(c)} onClose={() => setModal(null)} />}
    </div>
  )
}
