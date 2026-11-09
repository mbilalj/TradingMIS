import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import type { Shipment } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import { Badge, Kbd, Loading, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmt, fmtDate, money } from '../lib/format'

export default function ReceivingPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  useHotkeys({ 'alt+n': canEdit(user?.role, 'receiving') ? () => navigate('/receiving/new') : undefined })
  const { data, isLoading } = useQuery({ queryKey: ['shipments'], queryFn: Api.shipments })
  if (isLoading) return <Loading />

  return (
    <div>
      <PageHeader kicker="Inventory" title="Stock receiving" blurb="Every container that arrives at the Lahore warehouse. Each product in a container is a batch carrying its own manually entered cost, and stock is sold container by container."
        actions={canEdit(user?.role, 'receiving') && <button className="btn btn-primary" onClick={() => navigate('/receiving/new')}><Icon name="plus" size={16} /> Receive container<Kbd>Alt+N</Kbd></button>} />
      <DataTable<Shipment>
        searchable searchPlaceholder="Search container, receiving no., supplier or product…"
        rows={data ?? []} keyOf={(s) => s.id} onRowClick={(s) => navigate(`/shipments/${s.id}`)}
        columns={[
          { label: 'Container', render: (s) => <b>{s.containerNo ?? '—'}</b> },
          { label: 'Receiving', search: (s) => `${s.shipmentNo} ${s.containerNo ?? ''} ${s.supplier.name} ${s.batches.map((b) => `${b.batchNo} ${b.product.name} ${b.product.sku}`).join(' ')}`, render: (s) => <b>{s.shipmentNo}</b> },
          { label: 'Arrived', render: (s) => fmtDate(s.arrivalDate) },
          { label: 'Supplier', render: (s) => (<div>{s.supplier.name}<div className="muted" style={{ fontSize: 12 }}>{s.supplier.country}</div></div>) },
          { label: 'Contents', render: (s) => (<div style={{ maxWidth: 360 }}>{s.batches.slice(0, 3).map((b) => b.product.name).join(', ')}{s.batches.length > 3 && <span className="muted"> +{s.batches.length - 3} more</span>}</div>) },
          { label: 'Products', numeric: true, render: (s) => s.batches.length },
          { label: 'Warehouse', render: (s) => s.warehouse.name },
          { label: 'Total cost', numeric: true, render: (s) => fmt(s.totalCost) },
          { label: 'Owed to supplier', numeric: true, render: (s) => (s.payableAmount > 0 ? <Badge tone="warning">{money(s.payableAmount)}</Badge> : <span className="muted">—</span>) },
        ]}
        emptyText="No shipments yet. Use “Receive stock” when goods arrive."
      />
    </div>
  )
}
