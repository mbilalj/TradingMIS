import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useSuppliers } from '../api/hooks'
import { useAuth } from '../auth/AuthContext'
import { canEdit, canView } from '../auth/access'
import Icon from '../components/Icon'
import ReportView from '../components/ReportView'
import { Kbd, Kpi, Loading, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { money } from '../lib/format'
import { AdjustmentModal, PaySupplierModal } from './PaymentModals'
import { SupplierModal, toSupplierForm } from './SuppliersPage'

export default function SupplierDetailPage() {
  const { id } = useParams()
  const sid = Number(id)
  const { user } = useAuth()
  const navigate = useNavigate()
  const suppliers = useSuppliers()
  const [modal, setModal] = useState<'pay' | 'adj' | 'edit' | null>(null)
  useHotkeys({
    'alt+e': canEdit(user?.role, 'suppliers') ? () => setModal('edit') : undefined,
    'alt+p': canEdit(user?.role, 'supplierpay') ? () => setModal('pay') : undefined,
    'alt+a': canEdit(user?.role, 'supplierpay') ? () => setModal('adj') : undefined,
  })
  if (suppliers.isLoading) return <Loading />
  const row = suppliers.data?.find((s) => s.supplier.id === sid)
  if (!row) return <div className="empty">Supplier not found. <Link to="/suppliers">Back to suppliers</Link></div>
  const s = row.supplier
  const finance = canView(user?.role, 'supplierpay')

  return (
    <div className="section-gap" style={{ gap: 18 }}>
      <PageHeader kicker="Supplier account" title={s.name} blurb={[s.code, s.country, s.contact, s.address].filter(Boolean).join(' · ')}
        actions={<>
          <button className="btn btn-ghost" onClick={() => navigate('/suppliers')}>Back</button>
          {canEdit(user?.role, 'suppliers') && <button className="btn btn-secondary" onClick={() => setModal('edit')}><Icon name="edit" size={16} /> Edit<Kbd>Alt+E</Kbd></button>}
          {canEdit(user?.role, 'supplierpay') && <button className="btn btn-secondary" onClick={() => setModal('adj')}><Icon name="sliders" size={16} /> Adjustment<Kbd>Alt+A</Kbd></button>}
          {canEdit(user?.role, 'supplierpay') && <button className="btn btn-primary" onClick={() => setModal('pay')}><Icon name="card" size={16} /> Pay supplier<Kbd>Alt+P</Kbd></button>}
        </>} />
      {finance && (
        <div className="kpi-grid">
          <Kpi label="You owe" value={`Rs ${money(row.balance)}`} sub={row.balance < 0 ? 'Supplier owes you (advance)' : 'Closing balance'} icon="card" tone={row.balance > 0 ? 'danger' : 'success'} />
          <Kpi label="Opening balance" value={`Rs ${money(s.openingBalance)}`} icon="file" />
        </div>
      )}
      {finance ? <ReportView code="supplier-ledger" initialId={sid} lockPick embedded /> : <div className="empty">Ledger is restricted to finance users.</div>}
      {modal === 'pay' && <PaySupplierModal supplierId={sid} onClose={() => setModal(null)} />}
      {modal === 'adj' && <AdjustmentModal type="SUPPLIER" partyId={sid} name={s.name} onClose={() => setModal(null)} />}
      {modal === 'edit' && <SupplierModal id={sid} initial={toSupplierForm(s)} onClose={() => setModal(null)} />}
    </div>
  )
}
