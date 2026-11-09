import { useState } from 'react'
import { Api } from '../api/resources'
import { useAccounts } from '../api/hooks'
import type { Sale } from '../api/types'
import { Banner, Field, Modal } from '../components/ui'
import { money, qty, round2, today, toNum } from '../lib/format'
import { useAction } from '../lib/useAction'

export default function ReturnModal({ sale, onClose }: { sale: Sale; onClose: () => void }) {
  const accounts = useAccounts()
  const [date, setDate] = useState(today())
  const [notes, setNotes] = useState('')
  const [amounts, setAmounts] = useState<Record<number, string>>({})
  const [refund, setRefund] = useState('')
  const [accountId, setAccountId] = useState('')

  const rows = sale.lines.map((l) => {
    const left = (Number(l.baseQty) - Number(l.returnedBaseQty)) / Number(l.factor)
    const q = Math.min(toNum(amounts[l.id]), left)
    const share = Number(l.baseQty) > 0 ? (q * Number(l.factor)) / Number(l.baseQty) : 0
    return { l, left, q, value: round2(Number(l.lineTotal) * share) }
  })
  const value = round2(rows.reduce((s, r) => s + r.value, 0))
  const anything = rows.some((r) => r.q > 0)

  const save = useAction(
    () => Api.createReturn({
      saleId: sale.id, returnDate: date, notes, refundAmount: toNum(refund), refundAccountId: accountId ? Number(accountId) : null,
      lines: rows.filter((r) => r.q > 0).map((r) => ({ saleLineId: r.l.id, qty: r.q })),
    }),
    { ok: 'Return recorded — stock, balance and profit adjusted', invalidate: ['sales', 'returns', 'products', 'customers', 'dashboard', 'accounts', 'report', 'product-batches'], onDone: onClose },
  )

  return (
    <Modal wide title={`Return against ${sale.invoiceNo}`} onClose={onClose}
      footer={<><button className="btn btn-ghost" onClick={onClose}>Cancel</button>
        <button className="btn btn-primary" disabled={!anything || save.isPending || toNum(refund) > value + 0.01} onClick={() => save.mutate(undefined)}>{save.isPending ? 'Saving…' : 'Record return'}</button></>}>
      <table className="tbl compact">
        <thead><tr><th>Item</th><th>Batch</th><th className="n">Sold</th><th className="n">Can return</th><th className="n" style={{ width: 120 }}>Return qty</th><th className="n">Value</th></tr></thead>
        <tbody>{rows.map(({ l, left, q, value: v }) => (
          <tr key={l.id}>
            <td><b>{l.product.name}</b><div className="muted" style={{ fontSize: 11.5 }}>{l.product.sku}</div></td>
            <td>{l.batch.batchNo}</td>
            <td className="n">{qty(l.qty)} {l.unit.name}</td>
            <td className="n">{qty(left)}</td>
            <td><input className="input input-sm num" type="number" min="0" max={left} disabled={left <= 0} value={amounts[l.id] ?? ''} onChange={(e) => setAmounts((a) => ({ ...a, [l.id]: e.target.value }))} /></td>
            <td className="n">{q > 0 ? money(v) : '—'}</td>
          </tr>
        ))}</tbody>
      </table>
      <div className="form-grid" style={{ marginTop: 18 }}>
        <Field label="Return date"><input className="input" type="date" value={date} onChange={(e) => setDate(e.target.value)} /></Field>
        <Field label="Cash / bank refunded to customer" hint={`Up to Rs ${money(value)}. Leave 0 to credit the customer’s account instead.`}>
          <input className="input num" type="number" min="0" value={refund} onChange={(e) => setRefund(e.target.value)} placeholder="0.00" />
        </Field>
        {toNum(refund) > 0 && (
          <Field label="Refunded from">
            <select className="select" value={accountId} onChange={(e) => setAccountId(e.target.value)}>
              <option value="">Default cash account</option>
              {accounts.data?.filter((a) => a.account.active).map((a) => <option key={a.account.id} value={a.account.id}>{a.account.name}</option>)}
            </select>
          </Field>
        )}
        <Field label="Reason / notes" span2><input className="input" value={notes} onChange={(e) => setNotes(e.target.value)} /></Field>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 16, fontSize: 16, fontWeight: 760 }}><span>Return value</span><span className="tabnum">Rs {money(value)}</span></div>
      <div style={{ marginTop: 14 }}><Banner icon="info">Returned goods go back into stock in the same batch at their original cost. The customer’s balance, sales figures and profit are adjusted automatically.</Banner></div>
    </Modal>
  )
}
