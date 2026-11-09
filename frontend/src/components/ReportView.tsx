import { useMemo, useState, type ReactNode } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Api } from '../api/resources'
import { apiErrorMessage } from '../api/client'
import type { ReportCol, ReportResult } from '../api/types'
import { useAccounts, useCustomers, useProducts, useSettings, useSuppliers } from '../api/hooks'
import { reportDef } from '../lib/reports'
import { fmtDate, money, pct, qty, today, fmt } from '../lib/format'
import DateRange, { presetRange, type Range } from './DateRange'
import Icon from './Icon'
import { PortsideTrenovaMark, PrintCredit } from './Brand'
import { Banner, Loading } from './ui'

function cell(col: ReportCol, v: unknown): ReactNode {
  if (v == null || v === '') return <span className="muted">—</span>
  switch (col.type) {
    case 'money': {
      const n = Number(v)
      return <span className={n < 0 ? 'neg' : ''}>{n < 0 ? `(${money(Math.abs(n))})` : money(n)}</span>
    }
    case 'qty': return qty(v as number)
    case 'int': return fmt(v as number)
    case 'pct': return pct(v as number)
    case 'date': return fmtDate(String(v))
    default: return String(v)
  }
}

function rawCell(col: ReportCol, v: unknown): string {
  if (v == null) return ''
  return col.type === 'date' ? String(v) : String(v)
}

function csvEscape(s: string): string {
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s
}

function downloadCsv(report: ReportResult) {
  const header = report.columns.map((c) => csvEscape(c.label)).join(',')
  const lines = report.rows.map((r) => report.columns.map((c) => csvEscape(rawCell(c, r[c.key]))).join(','))
  const total = report.columns.some((c) => report.totals && c.key in report.totals)
    ? [report.columns.map((c, i) => csvEscape(i === 0 ? 'Total' : rawCell(c, report.totals[c.key]))).join(',')]
    : []
  const blob = new Blob(['﻿' + [header, ...lines, ...total].join('\n')], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${report.code}-${today()}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

interface Props {
  code: string
  /** Pre-select the customer/supplier/product/account. */
  initialId?: number
  /** Hide the picker (the parent already decided who the report is for). */
  lockPick?: boolean
  /** Embedded inside another page: no big title, smaller chrome. */
  embedded?: boolean
  initialRange?: Range
}

export default function ReportView({ code, initialId, lockPick, embedded, initialRange }: Props) {
  const def = reportDef(code)
  const settings = useSettings()
  const customers = useCustomers()
  const suppliers = useSuppliers()
  const accounts = useAccounts()
  const products = useProducts()

  const [range, setRange] = useState<Range>(initialRange ?? (def?.filter === 'asof' ? { from: presetRange('year').from, to: today() } : presetRange('month')))
  const [id, setId] = useState<number | undefined>(initialId)
  const [q, setQ] = useState('')
  const [type, setType] = useState('')

  const isAccountPick = def?.pick === 'cash' || def?.pick === 'bank'
  const accountOptions = (accounts.data ?? []).filter((a) => a.account.type === (def?.pick === 'bank' ? 'BANK' : 'CASH'))
  const effectiveId = isAccountPick ? (id ?? accountOptions[0]?.account.id) : id
  const blocked = (!!def?.pick && !!def.pickRequired && effectiveId == null) || (isAccountPick && effectiveId == null)

  const params = useMemo(() => ({
    from: def?.filter === 'range' ? range.from : undefined,
    to: def?.filter === 'none' ? undefined : range.to,
    id: effectiveId != null ? String(effectiveId) : undefined,
    q: q || undefined,
    type: type || undefined,
  }), [def, range, effectiveId, q, type])

  const query = useQuery({
    queryKey: ['report', code, params],
    queryFn: () => Api.report(code, params),
    enabled: !blocked,
  })
  const shown = query.data
  const loading = query.isLoading
  const error = query.error

  const periodLabel = def?.filter === 'range' ? `${fmtDate(range.from)} – ${fmtDate(range.to)}` : def?.filter === 'asof' ? `As of ${fmtDate(range.to)}` : ''

  return (
    <div className="section-gap">
      {/* Filters */}
      <div className="card no-print" style={{ padding: '12px 14px', display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
        {def?.filter === 'range' && <DateRange value={range} onChange={setRange} />}
        {def?.filter === 'asof' && (
          <label style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <span className="lbl">As of</span>
            <input className="input input-sm" type="date" value={range.to} onChange={(e) => setRange({ ...range, to: e.target.value })} style={{ width: 150 }} />
          </label>
        )}
        {def?.pick && !lockPick && (
          <select className="select select-sm" style={{ width: 220 }} value={effectiveId ?? ''} onChange={(e) => setId(e.target.value ? Number(e.target.value) : undefined)}>
            {!(def.pick === 'cash' || def.pick === 'bank') && <option value="">{def.pickRequired ? `Select ${def.pick}…` : `All ${def.pick}s`}</option>}
            {def.pick === 'customer' && customers.data?.filter((c) => !c.customer.walkIn).map((c) => <option key={c.customer.id} value={c.customer.id}>{c.customer.name}</option>)}
            {def.pick === 'supplier' && suppliers.data?.map((s) => <option key={s.supplier.id} value={s.supplier.id}>{s.supplier.name}</option>)}
            {def.pick === 'product' && products.data?.map((p) => <option key={p.product.id} value={p.product.id}>{p.product.sku} · {p.product.name}</option>)}
            {(def.pick === 'cash' || def.pick === 'bank') && accountOptions.map((a) => <option key={a.account.id} value={a.account.id}>{a.account.name}</option>)}
          </select>
        )}
        {def?.search && (
          <div className="search-box" style={{ width: 260 }}>
            <Icon name="search" size={16} />
            <input className="input" style={{ height: 34 }} placeholder="Search…" value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
        )}
        {def?.typeOptions && (
          <select className="select select-sm" style={{ width: 200 }} value={type} onChange={(e) => setType(e.target.value)}>
            {def.typeOptions.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        )}
        <div style={{ marginLeft: 'auto', display: 'flex', gap: 8 }}>
          <button className="btn btn-secondary btn-sm" disabled={!shown} onClick={() => shown && downloadCsv(shown)}><Icon name="download" size={15} /> Excel (CSV)</button>
          <button className="btn btn-secondary btn-sm" disabled={!shown} onClick={() => window.print()}><Icon name="printer" size={15} /> Print / PDF</button>
        </div>
      </div>

      {/* Print header */}
      <div className="print-only" style={{ marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}><PortsideTrenovaMark size={36} /><div style={{ fontSize: 20, fontWeight: 800 }}>{settings.data?.['business.name']}</div></div>
        <div style={{ fontSize: 17, fontWeight: 700, marginTop: 6 }}>{shown?.title ?? def?.title}</div>
        <div className="muted">{[periodLabel, shown?.subtitle].filter(Boolean).join(' · ')} · Generated {fmtDate(today())}</div>
      </div>

      {blocked && <Banner icon="info">Choose a {def?.pick} above to run this report.</Banner>}
      {error ? <Banner tone="danger" icon="alert">{apiErrorMessage(error)}</Banner> : null}
      {loading && <Loading />}

      {shown && (
        <div className="card" style={{ overflow: 'hidden' }}>
          {!embedded && (
            <div style={{ padding: '14px 18px', borderBottom: '1px solid var(--line)' }}>
              <div className="card-title">{shown.title}</div>
              <div className="card-sub">{[periodLabel, shown.subtitle].filter(Boolean).join(' · ')}</div>
            </div>
          )}
          <div className="table-scroll">
            <table className="tbl compact">
              <thead>
                <tr>{shown.columns.map((c) => <th key={c.key} className={['money', 'qty', 'int', 'pct'].includes(c.type) ? 'n' : ''}>{c.label}</th>)}</tr>
              </thead>
              <tbody>
                {shown.rows.length === 0 && <tr><td colSpan={shown.columns.length}><div className="empty">No data for this selection.</div></td></tr>}
                {shown.rows.map((r, i) => (
                  <tr key={i} className={r._style ? `st-${String(r._style)}` : ''}>
                    {shown.columns.map((c) => (
                      <td key={c.key} className={['money', 'qty', 'int', 'pct'].includes(c.type) ? 'n' : ''}>{cell(c, r[c.key])}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
              {shown.rows.length > 0 && shown.columns.some((c, i) => i > 0 && c.key in (shown.totals ?? {})) && (
                <tfoot>
                  <tr>
                    {shown.columns.map((c, i) => (
                      <td key={c.key} className={['money', 'qty', 'int', 'pct'].includes(c.type) ? 'n' : ''}>
                        {i === 0 ? 'Total' : c.key in shown.totals ? cell(c, shown.totals[c.key]) : ''}
                      </td>
                    ))}
                  </tr>
                </tfoot>
              )}
            </table>
          </div>
        </div>
      )}
      {shown && <div className="print-only"><PrintCredit /></div>}
    </div>
  )
}
