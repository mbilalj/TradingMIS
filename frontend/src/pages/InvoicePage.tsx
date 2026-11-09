import { useEffect, useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { Api } from '../api/resources'
import { useSettings } from '../api/hooks'
import type { Sale } from '../api/types'
import { useAuth } from '../auth/AuthContext'
import { canEdit, canView } from '../auth/access'
import Icon from '../components/Icon'
import { PortsideTrenovaMark, PrintCredit } from '../components/Brand'
import { Badge, Card, Loading, PageHeader } from '../components/ui'
import { fmtDate, money, qty, titleCase } from '../lib/format'
import { paymentBadge } from './SalesPage'
import ReturnModal from './ReturnModal'

interface Merged { key: string; name: string; sku: string; unit: string; qty: number; rate: number; discount: number; net: number; tax: number; total: number }

function merge(sale: Sale): Merged[] {
  const m = new Map<string, Merged>()
  for (const l of sale.lines) {
    const key = `${l.product.id}|${l.unit.id}|${l.rate}|${l.taxPct}`
    const e = m.get(key) ?? { key, name: l.product.name, sku: l.product.sku, unit: l.unit.name, qty: 0, rate: Number(l.rate), discount: 0, net: 0, tax: 0, total: 0 }
    e.qty += Number(l.qty); e.discount += Number(l.discount); e.net += Number(l.netAmount); e.tax += Number(l.taxAmount); e.total += Number(l.lineTotal)
    m.set(key, e)
  }
  return [...m.values()]
}

export default function InvoicePage() {
  const { id } = useParams()
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const { user } = useAuth()
  const settings = useSettings()
  const [returning, setReturning] = useState(false)
  const sale = useQuery({ queryKey: ['sales', 'one', id], queryFn: () => Api.sale(Number(id)) })
  const returns = useQuery({ queryKey: ['returns', id], queryFn: () => Api.returnsFor(Number(id)), enabled: canView(user?.role, 'returns') })

  const ready = !!sale.data && !!settings.data
  useEffect(() => {
    if (ready && params.get('print') === '1') {
      const t = setTimeout(() => window.print(), 350)
      return () => clearTimeout(t)
    }
  }, [ready, params])

  const lines = useMemo(() => (sale.data ? merge(sale.data) : []), [sale.data])
  if (sale.isLoading || !sale.data || !settings.data) return <Loading />
  const s = sale.data
  const biz = settings.data
  const balance = Math.max(0, Number(s.outstanding))
  const credit = Math.max(0, -Number(s.outstanding))

  return (
    <div>
      <PageHeader kicker={s.type === 'WHOLESALE' ? 'Wholesale invoice' : 'Retail invoice'} title={s.invoiceNo}
        actions={<>
          <button className="btn btn-ghost" onClick={() => navigate('/sales')}>Back</button>
          {canEdit(user?.role, 'returns') && <button className="btn btn-secondary" onClick={() => setReturning(true)}><Icon name="undo" size={16} /> Return items</button>}
          <button className="btn btn-primary" onClick={() => window.print()}><Icon name="printer" size={16} /> Print / Save PDF</button>
        </>} />

      <div className="invoice-sheet">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 24, flexWrap: 'wrap' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <PortsideTrenovaMark size={50} />
              <div>
                <div style={{ fontSize: 21, fontWeight: 780, letterSpacing: '-0.02em' }}>{biz['business.name']}</div>
                <div className="muted" style={{ fontSize: 12.5 }}>{biz['business.address']}</div>
              </div>
            </div>
            <div className="muted" style={{ fontSize: 12.5, marginTop: 8 }}>
              {[biz['business.phone'], biz['business.email'], biz['business.taxNo'] && `Tax no. ${biz['business.taxNo']}`].filter(Boolean).join('  ·  ')}
            </div>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div className="inv-title">INVOICE</div>
            <div style={{ fontWeight: 700, fontSize: 15, marginTop: 4 }}>{s.invoiceNo}</div>
            <div className="muted">Date: {fmtDate(s.saleDate)}</div>
            <div style={{ marginTop: 8 }}>{paymentBadge(s)}</div>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24, margin: '30px 0 22px' }}>
          <div>
            <div className="lbl" style={{ marginBottom: 5 }}>Billed to</div>
            <div style={{ fontWeight: 700, fontSize: 15 }}>{s.customer.walkIn ? 'Walk-in customer' : s.customer.name}</div>
            {!s.customer.walkIn && <div className="text-2" style={{ fontSize: 13 }}>{[s.customer.address, s.customer.phone].filter(Boolean).map((t, i) => <div key={i}>{t}</div>)}</div>}
          </div>
          <div style={{ textAlign: 'right' }}>
            <div className="lbl" style={{ marginBottom: 5 }}>Payment</div>
            <div style={{ fontWeight: 650 }}>{s.paymentMethod ? titleCase(s.paymentMethod) : '—'}</div>
            <div className="text-2" style={{ fontSize: 13 }}>{s.type === 'WHOLESALE' ? 'Wholesale' : 'Retail'} sale{s.createdBy ? ` · by ${s.createdBy}` : ''}</div>
          </div>
        </div>

        <table className="tbl">
          <thead><tr><th>#</th><th>Item</th><th className="n">Qty</th><th>Unit</th><th className="n">Rate</th><th className="n">Discount</th><th className="n">Tax</th><th className="n">Amount</th></tr></thead>
          <tbody>
            {lines.map((l, i) => (
              <tr key={l.key}>
                <td className="muted">{i + 1}</td>
                <td><div style={{ fontWeight: 650 }}>{l.name}</div><div className="muted" style={{ fontSize: 11.5 }}>{l.sku}</div></td>
                <td className="n">{qty(l.qty)}</td><td>{l.unit}</td><td className="n">{money(l.rate)}</td>
                <td className="n">{l.discount ? money(l.discount) : '—'}</td><td className="n">{l.tax ? money(l.tax) : '—'}</td>
                <td className="n" style={{ fontWeight: 650 }}>{money(l.total)}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 20 }}>
          <div style={{ width: 320, display: 'grid', gap: 8, fontSize: 14 }}>
            <Line k="Subtotal" v={money(s.grossAmount)} />
            {Number(s.discountTotal) > 0 && <Line k="Discount" v={`– ${money(s.discountTotal)}`} />}
            {Number(s.taxTotal) > 0 && <Line k="Tax" v={money(s.taxTotal)} />}
            <div style={{ borderTop: '2px solid var(--text)', paddingTop: 8, display: 'flex', justifyContent: 'space-between', fontSize: 18, fontWeight: 800 }}><span>Total</span><span className="tabnum">Rs {money(s.total)}</span></div>
            {Number(s.returnedAmount) > 0 && <Line k="Returned" v={`– ${money(s.returnedAmount)}`} />}
            <Line k="Paid" v={money(s.paidAmount)} />
            <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 800, fontSize: 15, color: balance > 0 ? 'var(--danger)' : 'var(--success)' }}>
              <span>{credit > 0 ? 'Credit due to customer' : 'Remaining balance'}</span><span className="tabnum">Rs {money(balance || credit)}</span>
            </div>
          </div>
        </div>

        {s.remarks && <div style={{ marginTop: 26 }}><div className="lbl">Notes</div><div className="text-2">{s.remarks}</div></div>}
        <div className="muted" style={{ marginTop: 40, paddingTop: 14, borderTop: '1px solid var(--line)', textAlign: 'center', fontSize: 12.5 }}>{biz['invoice.footer']}</div>
        <PrintCredit />
      </div>

      {(returns.data?.length ?? 0) > 0 && (
        <div className="no-print" style={{ marginTop: 22 }}>
          <Card title="Returns against this invoice" pad={false}>
            <table className="tbl compact">
              <thead><tr><th>Return</th><th>Date</th><th>Items</th><th className="n">Value</th><th className="n">Refunded</th><th>Notes</th></tr></thead>
              <tbody>{returns.data?.map((r) => (
                <tr key={r.id}><td><b>{r.returnNo}</b></td><td>{fmtDate(r.returnDate)}</td>
                  <td>{r.lines.map((l) => `${l.product.name} × ${qty(l.qty)}`).join(', ')}</td>
                  <td className="n">{money(r.total)}</td><td className="n">{money(r.refundAmount)}</td><td className="text-2">{r.notes ?? '—'}</td></tr>
              ))}</tbody>
            </table>
          </Card>
        </div>
      )}
      {!s.customer.walkIn && <div className="no-print" style={{ marginTop: 14 }}><Badge tone="info">Customer</Badge> <Link to={`/customers/${s.customer.id}`}>Open {s.customer.name}’s ledger →</Link></div>}

      {returning && <ReturnModal sale={s} onClose={() => setReturning(false)} />}
    </div>
  )
}

function Line({ k, v }: { k: string; v: string }) {
  return <div style={{ display: 'flex', justifyContent: 'space-between' }}><span className="text-2">{k}</span><span className="tabnum">{v}</span></div>
}
