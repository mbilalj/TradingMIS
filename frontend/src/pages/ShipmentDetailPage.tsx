import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Api } from '../api/resources'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import Attachments from '../components/Attachments'
import Icon from '../components/Icon'
import { Badge, Card, Kbd, Kpi, Loading, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, fmtDate, money, qty } from '../lib/format'
import ExpenseModal from './ExpenseModal'

export default function ShipmentDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const [paying, setPaying] = useState(false)
  useHotkeys({ 'alt+n': canEdit(user?.role, 'expenses') ? () => setPaying(true) : undefined })
  const { data, isLoading } = useQuery({ queryKey: ['shipments', id], queryFn: () => Api.shipment(Number(id)) })
  if (isLoading || !data) return <Loading />
  const { shipment: s, batches, payments } = data
  const paidTotal = payments.reduce((a, p) => a + Number(p.amount), 0)

  return (
    <div className="section-gap" style={{ gap: 18 }}>
      <PageHeader kicker={<><Link to="/receiving">Stock receiving</Link> / container</>} title={s.containerNo ? `Container ${s.containerNo}` : s.shipmentNo}
        blurb={`${s.shipmentNo} · Received ${fmtDate(s.arrivalDate)} from ${s.supplier.name} into ${s.warehouse.name}.`}
        actions={<button className="btn btn-secondary" onClick={() => navigate('/receiving')}>Back to list</button>} />

      <div className="kpi-grid">
        <Kpi label="Shipment value" value={`Rs ${fmt(s.totalCost)}`} sub={`${batches.length} batch${batches.length === 1 ? '' : 'es'}`} icon="box" />
        <Kpi label="Owed to supplier" value={`Rs ${fmt(s.payableAmount)}`} sub={s.payableAmount > 0 ? <Link to={`/suppliers/${s.supplier.id}`}>See supplier ledger →</Link> : 'Nothing owed'} icon="building" tone="warning" />
        <Kpi label="Non-operating payments" value={`Rs ${fmt(paidTotal)}`} sub="Customs, clearing, freight — excluded from profit" icon="receipt" tone="info" />
      </div>

      <Card title="Batches" sub="Each batch keeps its own cost, so profit on every sale uses the right figure." pad={false}>
        <div className="table-scroll">
          <table className="tbl">
            <thead><tr><th>Batch</th><th>Product</th><th className="n">Received</th><th>Entered as</th><th className="n">Cost / base unit</th><th className="n">Entered cost</th><th className="n">On hand now</th></tr></thead>
            <tbody>
              {batches.map(({ batch: b, onHand }) => (
                <tr key={b.id}>
                  <td><b>{b.batchNo}</b></td>
                  <td><div style={{ fontWeight: 650 }}>{b.product.name}</div><div className="muted" style={{ fontSize: 12 }}>{b.product.sku}</div></td>
                  <td className="n">{qty(b.receivedQty)} {b.product.baseUnit.name}</td>
                  <td>{qty(b.enteredQty)} {b.enteredUnit.name}</td>
                  <td className="n">{money(b.unitCost)}</td>
                  <td className="n">{money(b.enteredUnitCost)} / {b.enteredUnit.name}</td>
                  <td className="n"><Badge tone={onHand <= 0 ? 'neutral' : 'success'}>{qty(onHand)}</Badge></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <div style={{ display: 'grid', gap: 16, gridTemplateColumns: 'minmax(0, 1.4fr) minmax(0, 1fr)' }}>
        <Card title="Payments against this shipment" sub="Non-operating payments: they reduce cash/bank but never appear in the Profit & Loss."
          actions={canEdit(user?.role, 'expenses') && <button className="btn btn-secondary btn-sm" onClick={() => setPaying(true)}><Icon name="plus" size={15} /> Record payment<Kbd>Alt+N</Kbd></button>}>
          {payments.length === 0 ? <div className="muted">No payments recorded for this shipment yet.</div> : (
            <table className="tbl compact">
              <thead><tr><th>Date</th><th>Ref</th><th>Category</th><th>Paid from</th><th className="n">Amount</th></tr></thead>
              <tbody>{payments.map((p) => (
                <tr key={p.id}><td>{fmtDate(p.expenseDate)}</td><td>{p.expenseNo}</td><td>{p.category.name}</td><td>{p.account.name}</td><td className="n">{money(p.amount)}</td></tr>
              ))}</tbody>
            </table>
          )}
        </Card>
        <div className="section-gap">
          <Card title="Documents"><Attachments ownerType="SHIPMENT" ownerId={s.id} canUpload={canEdit(user?.role, 'receiving')} /></Card>
          {s.notes && <Card title="Notes"><div className="text-2">{s.notes}</div></Card>}
        </div>
      </div>

      {paying && <ExpenseModal onClose={() => setPaying(false)} presetNature="NON_OPERATING" presetShipmentId={s.id} />}
    </div>
  )
}
