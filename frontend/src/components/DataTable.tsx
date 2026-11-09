import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { useHotkeys } from '../lib/hotkeys'
import Icon from './Icon'

export interface Column<T> {
  label: string
  render: (row: T) => ReactNode
  numeric?: boolean
  /** Text used by the built-in search box; defaults to rendered text of searchable columns. */
  search?: (row: T) => string
  width?: number | string
}

interface Props<T> {
  columns: Column<T>[]
  rows: T[]
  keyOf: (row: T) => string | number
  /** Opens the row (click or Enter). */
  onRowClick?: (row: T) => void
  /** Alt+E on the highlighted row (Enter too when there is no onRowClick). */
  onEdit?: (row: T) => void
  /** Delete / Alt+D on the highlighted row; the page is responsible for confirming. */
  onDelete?: (row: T) => void
  footer?: ReactNode
  emptyText?: string
  searchable?: boolean
  searchPlaceholder?: string
  toolbar?: ReactNode
  compact?: boolean
  maxHeight?: number
}

export default function DataTable<T>({
  columns, rows, keyOf, onRowClick, onEdit, onDelete, footer, emptyText, searchable, searchPlaceholder, toolbar, compact, maxHeight,
}: Props<T>) {
  const [q, setQ] = useState('')
  const [sel, setSel] = useState(-1)
  const wrap = useRef<HTMLDivElement>(null)
  const searchBox = useRef<HTMLInputElement>(null)
  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase()
    if (!needle) return rows
    return rows.filter((r) => columns.some((c) => (c.search ? c.search(r) : '').toLowerCase().includes(needle)))
  }, [rows, q, columns])

  useEffect(() => { setSel(-1) }, [q, filtered.length])
  useEffect(() => {
    wrap.current?.querySelector<HTMLElement>('tr.selected')?.scrollIntoView({ block: 'nearest' })
  }, [sel])

  // Row shortcuts only react when nothing else has focus (or focus is inside this table), so forms stay undisturbed.
  const mine = () => { const a = document.activeElement; return !a || a === document.body || !!wrap.current?.contains(a) }
  const current = filtered[sel] as T | undefined
  const move = (d: number) => { if (mine() && filtered.length) setSel((i) => Math.max(0, Math.min(filtered.length - 1, i + d))) }
  const act = (fn?: (row: T) => void) => { if (fn && current && mine()) fn(current) }
  useHotkeys({
    '/': searchable ? () => searchBox.current?.focus() : undefined,
    arrowdown: () => move(1),
    arrowup: () => move(-1),
    enter: () => act(onRowClick ?? onEdit),
    'alt+e': onEdit ? () => { if (current) onEdit(current) } : undefined,
    delete: onDelete ? () => act(onDelete) : undefined,
    'alt+d': onDelete ? () => { if (current) onDelete(current) } : undefined,
  })
  const hints = [
    filtered.length > 0 && '↑↓ select', (onRowClick ?? onEdit) && 'Enter open', onEdit && 'Alt+E edit', onDelete && 'Del delete', searchable && '/ search',
  ].filter(Boolean).join('  ·  ')

  return (
    <div className="card" style={{ overflow: 'hidden' }} ref={wrap}>
      {(searchable || toolbar) && (
        <div className="no-print table-toolbar">
          {searchable ? (
            <div className="search-box" style={{ width: 300 }}>
              <Icon name="search" size={16} />
              <input ref={searchBox} className="input" placeholder={searchPlaceholder ?? 'Filter this list…'} value={q} onChange={(e) => setQ(e.target.value)} 
                onKeyDown={(e) => { if (e.key === 'ArrowDown' && filtered.length) { e.preventDefault(); e.currentTarget.blur(); setSel(0) } else if (e.key === 'Escape') { setQ(''); e.currentTarget.blur() } }} />
            </div>
          ) : <span />}
          {toolbar && <div className="tb-right">{toolbar}</div>}
        </div>
      )}
      <div className="table-scroll" style={maxHeight ? { maxHeight } : undefined}>
        <table className={`tbl ${compact ? 'compact' : ''}`}>
          <thead>
            <tr>{columns.map((c) => <th key={c.label} className={c.numeric ? 'n' : ''} style={c.width ? { width: c.width } : undefined}>{c.label}</th>)}</tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr><td colSpan={columns.length}><div className="empty">{emptyText ?? 'Nothing to show yet.'}</div></td></tr>
            )}
            {filtered.map((row, i) => (
              <tr key={keyOf(row)} className={`${onRowClick ? 'clickable' : ''} ${i === sel ? 'selected' : ''}`}
                onClick={() => { setSel(i); onRowClick?.(row) }}>
                {columns.map((c) => <td key={c.label} className={c.numeric ? 'n' : ''}>{c.render(row)}</td>)}
              </tr>
            ))}
          </tbody>
          {footer && <tfoot>{footer}</tfoot>}
        </table>
      </div>
      {hints && filtered.length > 0 && <div className="no-print table-hint">{hints}</div>}
    </div>
  )
}
