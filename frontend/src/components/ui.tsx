import { useEffect, useRef, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import Icon, { type IconName } from './Icon'
import { useHotkeys } from '../lib/hotkeys'

/** Small key-cap hint shown on buttons, e.g. <Kbd>Alt+N</Kbd>. */
export function Kbd({ children }: { children: ReactNode }) {
  return <kbd className="kbd">{children}</kbd>
}

export function PageHeader({ kicker, title, blurb, actions }: { kicker?: ReactNode; title: string; blurb?: string; actions?: ReactNode }) {
  return (
    <div className="page-head no-print">
      <div style={{ minWidth: 0 }}>
        {kicker && <div className="kicker" style={{ marginBottom: 4 }}>{kicker}</div>}
        <h1 className="page-title">{title}</h1>
        {blurb && <div className="page-blurb">{blurb}</div>}
      </div>
      {actions && <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>{actions}</div>}
    </div>
  )
}

export function Card({ title, sub, actions, children, pad = true, className }: {
  title?: string; sub?: string; actions?: ReactNode; children: ReactNode; pad?: boolean; className?: string
}) {
  return (
    <section className={`card ${className ?? ''}`}>
      {(title || actions) && (
        <div className="card-head">
          <div>
            {title && <div className="card-title">{title}</div>}
            {sub && <div className="card-sub">{sub}</div>}
          </div>
          {actions}
        </div>
      )}
      <div className={pad ? 'card-pad' : ''}>{children}</div>
    </section>
  )
}

export function Kpi({ label, value, sub, icon, tone = 'primary' }: {
  label: string; value: ReactNode; sub?: ReactNode; icon: IconName; tone?: 'primary' | 'success' | 'danger' | 'warning' | 'info'
}) {
  return (
    <div className="card kpi">
      <div className={`kpi-icon ${tone}`}><Icon name={icon} size={20} /></div>
      <div style={{ minWidth: 0 }}>
        <div className="lbl">{label}</div>
        <div className="kpi-value">{value}</div>
        {sub && <div className="kpi-sub">{sub}</div>}
      </div>
    </div>
  )
}

export function Badge({ tone = 'neutral', children }: { tone?: 'neutral' | 'primary' | 'success' | 'danger' | 'warning' | 'info'; children: ReactNode }) {
  return <span className={`badge ${tone === 'neutral' ? '' : tone}`}>{children}</span>
}

export function Field({ label, hint, children, span2 }: { label: string; hint?: ReactNode; children: ReactNode; span2?: boolean }) {
  return (
    <label className={`field ${span2 ? 'span-2' : ''}`}>
      <span className="lbl">{label}</span>
      {children}
      {hint && <div className="hint">{hint}</div>}
    </label>
  )
}

export function Modal({ title, onClose, children, footer, wide, full }: {
  title: string; onClose: () => void; children: ReactNode; footer?: ReactNode; wide?: boolean; /** Near full-screen window, e.g. the product browser. */ full?: boolean
}) {
  const self = useRef<HTMLDivElement>(null)
  useEffect(() => {
    // Only the top-most dialog reacts, so Esc in a window opened from a dialog closes just that window.
    const onKey = (e: KeyboardEvent) => {
      const all = document.querySelectorAll('.modal')
      if (e.key === 'Escape' && all[all.length - 1] === self.current) onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])
  // Ctrl+S / Ctrl+Enter presses the dialog's primary button, so every create/edit form saves from the keyboard.
  const submit = () => {
    const dialogs = document.querySelectorAll('.modal')
    dialogs[dialogs.length - 1]?.querySelector<HTMLButtonElement>('.modal-foot .btn-primary:not(:disabled)')?.click()
  }
  useHotkeys({ 'ctrl+s': submit, 'ctrl+enter': submit }, { modal: true })
  return createPortal(
    <div className="overlay no-print" onMouseDown={(e) => { if (e.target === e.currentTarget) onClose() }}>
      <div ref={self} className={`modal ${wide ? 'wide' : ''} ${full ? 'full' : ''}`} role="dialog" aria-modal="true" aria-label={title}>
        <div className="modal-head">
          <h2 style={{ fontSize: 17, fontWeight: 720 }}>{title}</h2>
          <button className="btn btn-ghost btn-icon btn-sm" onClick={onClose} aria-label="Close"><Icon name="x" /></button>
        </div>
        <div className="modal-body">{children}</div>
        {footer && <div className="modal-foot">{footer}</div>}
      </div>
    </div>,
    document.body,
  )
}

export function Segmented<T extends string>({ value, onChange, options }: {
  value: T; onChange: (v: T) => void; options: { value: T; label: string }[]
}) {
  return (
    <div className="seg">
      {options.map((o) => (
        <button key={o.value} type="button" className={o.value === value ? 'on' : ''} onClick={() => onChange(o.value)}>{o.label}</button>
      ))}
    </div>
  )
}

export function Tabs<T extends string>({ value, onChange, options }: {
  value: T; onChange: (v: T) => void; options: { value: T; label: string }[]
}) {
  return (
    <div className="tabs no-print">
      {options.map((o) => (
        <button key={o.value} type="button" className={o.value === value ? 'on' : ''} onClick={() => onChange(o.value)}>{o.label}</button>
      ))}
    </div>
  )
}

export function Banner({ tone = 'info', children, icon = 'info' }: { tone?: 'info' | 'warn' | 'danger'; children: ReactNode; icon?: IconName }) {
  return (
    <div className={`banner ${tone}`}>
      <Icon name={icon} size={18} />
      <div>{children}</div>
    </div>
  )
}

export function Empty({ children }: { children: ReactNode }) {
  return <div className="empty">{children}</div>
}

export function Loading() {
  return <div className="empty">Loading…</div>
}
