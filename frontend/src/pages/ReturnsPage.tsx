import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate } from 'react-router-dom'
import { Api } from '../api/resources'
import type { Sale, SaleReturn } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit } from '../auth/access'
import DataTable from '../components/DataTable'
import Icon from '../components/Icon'
import { Banner, Kbd, Loading, Modal, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { fmtDate, money, qty } from '../lib/format'
import ReturnModal from './ReturnModal'

function PickInvoice({ onPick, onClose }: { onPick: (s: Sale) => void; onClose: () => void }) {
  const [q, setQ] = useState('')
  const list = useQuery({ queryKey: ['sales', 'pick', q], queryFn: () => Api.sales({ q: q || undefined }) })
  return (
    <Modal title="Find the invoice being returned" onClose={onClose}>
      <input className="input" autoFocus placeholder="Invoice number or customer name…" value={q} onChange={(e) => setQ(e.target.value)} />
      <div style={{ marginTop: 12, maxHeight: 360, overflowY: 'auto', display: 'grid', gap: 6 }}>
        {(list.data ?? []).slice(0, 30).map((s) => (
          <button key={s.id} className="btn btn-secondary" style={{ justifyContent: 'space-between', height: 'auto', padding: '10px 14px' }} onClick={() => onPick(s)}>
            <span><b>{s.invoiceNo}</b> · {s.customer.walkIn ? 'Walk-in' : s.customer.name}</span>
            <span className="muted">{fmtDate(s.saleDate)} · Rs {money(s.total)}</span>
          </button>
        ))}
        {list.data?.length === 0 && <div className="empty">No invoices match.</div>}
      </div>
    </Modal>
  )
}

export default function ReturnsPage() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const { data, isLoading } = useQuery({ queryKey: ['returns'], queryFn: Api.returns })
  const [picking, setPicking] = useState(false)
  const [sale, setSale] = useState<Sale | null>(null)
  useHotkeys({ 'alt+n': canEdit(user?.role, 'returns') ? () => setPicking(true) : undefined })
  if (isLoading) return <Loading />

  return (
    <div>
      <PageHeader kicker="Sales" title="Sales returns" blurb="Returned goods go back to the batch they came from. The customer’s balance, sales figures and profit are adjusted, and the history is kept here."
        actions={canEdit(user?.role, 'returns') && <button className="btn btn-primary" onClick={() => setPicking(true)}><Icon name="plus" size={16} /> New return<Kbd>Alt+N</Kbd></button>} />
      <Banner icon="info">To return items, find the original invoice, then choose the quantities coming back.</Banner>
      <div style={{ height: 16 }} />
      <DataTable<SaleReturn>
        searchable searchPlaceholder="Search return, invoice or customer…" rows={data ?? []} keyOf={(r) => r.id} onRowClick={(r) => navigate(`/sales/${r.sale.id}`)}
        columns={[
          { label: 'Return', search: (r) => `${r.returnNo} ${r.sale.invoiceNo} ${r.customer.name}`, render: (r) => <b>{r.returnNo}</b> },
          { label: 'Date', render: (r) => fmtDate(r.returnDate) },
          { label: 'Invoice', render: (r) => <Link to={`/sales/${r.sale.id}`} onClick={(e) => e.stopPropagation()}>{r.sale.invoiceNo}</Link> },
          { label: 'Customer', render: (r) => (r.customer.walkIn ? <span className="muted">Walk-in</span> : r.customer.name) },
          { label: 'Items', render: (r) => <span className="text-2">{r.lines.map((l) => `${l.product.name} × ${qty(l.qty)}`).join(', ')}</span> },
          { label: 'Value', numeric: true, render: (r) => money(r.total) },
          { label: 'Refunded', numeric: true, render: (r) => (Number(r.refundAmount) ? money(r.refundAmount) : <span className="muted">—</span>) },
          { label: 'Reason', render: (r) => <span className="text-2">{r.notes ?? '—'}</span> },
        ]}
        emptyText="No returns recorded."
      />
      {picking && <PickInvoice onClose={() => setPicking(false)} onPick={(s) => { setPicking(false); setSale(s) }} />}
      {sale && <ReturnModal sale={sale} onClose={() => setSale(null)} />}
    </div>
  )
}
