import { useEffect, useLayoutEffect, useMemo, useRef, useState, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import Icon from './Icon'

export interface ComboOption {
  value: string
  /** Text shown in the box once chosen. */
  label: string
  /** Extra text that is searched but not shown in the box. */
  keywords?: string
  /** Richer content for the dropdown row; defaults to the label. */
  render?: ReactNode
}

/**
 * Type-ahead picker: start typing a code or name, ↑/↓ to move, Enter or Tab to choose, Esc to cancel.
 * Every word typed must appear somewhere in the option, so "led 12" finds "ELE-LED12 · LED Bulb 12W".
 * The list floats above the page (it is never clipped by a scrolling table), and with `onBrowse`
 * a list button / F4 opens the full browse window.
 */
export default function Combobox({ options, value, onChange, placeholder, small, autoFocus, disabled, inputRef, onPicked, emptyText, data, onBrowse }: {
  options: ComboOption[]
  value: string
  onChange: (value: string) => void
  placeholder?: string
  small?: boolean
  autoFocus?: boolean
  disabled?: boolean
  inputRef?: (el: HTMLInputElement | null) => void
  /** Called after the user picks an option, e.g. to move focus to the next field. */
  onPicked?: (value: string) => void
  emptyText?: string
  /** Rendered as data-* attributes on the input, used to jump focus between cells. */
  data?: Record<string, string | number>
  /** Opens a full-size browse window; shown as a list button and bound to F4. */
  onBrowse?: () => void
}) {
  const selected = options.find((o) => o.value === value)
  const [text, setText] = useState(selected?.label ?? '')
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(0)
  const [pos, setPos] = useState<{ left: number; top: number; width: number; maxHeight: number; up: boolean } | null>(null)
  const box = useRef<HTMLDivElement>(null)
  const list = useRef<HTMLDivElement>(null)

  // Keep the box in step when the value changes from outside (reset, edit, quick-add).
  useEffect(() => { if (!open) setText(selected?.label ?? '') }, [selected?.label, open])

  const matches = useMemo(() => {
    const words = text.trim().toLowerCase().split(/\s+/).filter(Boolean)
    // Showing the full list when the text is just the current selection lets the user re-open and browse.
    if (!words.length || text === selected?.label) return options.slice(0, 200)
    return options.filter((o) => {
      const hay = `${o.label} ${o.keywords ?? ''}`.toLowerCase()
      return words.every((w) => hay.includes(w))
    }).slice(0, 200)
  }, [options, text, selected?.label])

  useEffect(() => { setActive(0) }, [text, open])
  useEffect(() => {
    if (!open) return
    list.current?.querySelector<HTMLElement>('[data-active="true"]')?.scrollIntoView({ block: 'nearest' })
  }, [active, open])

  // Position the floating list against the input; flip upwards when there is more room above.
  useLayoutEffect(() => {
    if (!open) return
    const place = () => {
      const r = box.current?.getBoundingClientRect()
      if (!r) return
      const below = window.innerHeight - r.bottom - 12
      const above = r.top - 12
      const up = below < 240 && above > below
      setPos({ left: r.left, top: up ? r.top - 4 : r.bottom + 4, width: Math.max(r.width, 380), maxHeight: Math.min(420, up ? above : below), up })
    }
    place()
    window.addEventListener('scroll', place, true)
    window.addEventListener('resize', place)
    return () => { window.removeEventListener('scroll', place, true); window.removeEventListener('resize', place) }
  }, [open])

  useEffect(() => {
    const onDoc = (e: MouseEvent) => {
      const t = e.target as Node
      if (box.current?.contains(t) || list.current?.contains(t)) return
      setOpen(false)
    }
    document.addEventListener('mousedown', onDoc)
    return () => document.removeEventListener('mousedown', onDoc)
  }, [])

  function pick(o: ComboOption) {
    onChange(o.value)
    setText(o.label)
    setOpen(false)
    onPicked?.(o.value)
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'ArrowDown') { e.preventDefault(); setOpen(true); setActive((a) => Math.min(a + 1, matches.length - 1)) }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((a) => Math.max(a - 1, 0)) }
    else if (e.key === 'F4' && onBrowse) { e.preventDefault(); e.stopPropagation(); setOpen(false); onBrowse() }
    else if (e.key === 'Enter') {
      if (open && matches[active]) { e.preventDefault(); e.stopPropagation(); pick(matches[active]) }
    } else if (e.key === 'Tab') {
      // Tab accepts the highlighted match only when the user typed something new.
      if (open && text !== selected?.label && matches[active]) pick(matches[active])
      setOpen(false)
    } else if (e.key === 'Escape') {
      if (open) { e.stopPropagation(); e.preventDefault(); setOpen(false); setText(selected?.label ?? '') }
    }
  }

  return (
    <div ref={box} style={{ position: 'relative' }}>
      <input
        ref={inputRef} {...Object.fromEntries(Object.entries(data ?? {}).map(([k, v]) => [`data-${k}`, v]))} className={`input ${small ? 'input-sm' : ''}`} value={text} placeholder={placeholder} autoFocus={autoFocus} disabled={disabled}
        role="combobox" aria-expanded={open} aria-autocomplete="list" autoComplete="off" style={onBrowse ? { paddingRight: 34 } : undefined}
        onChange={(e) => { setText(e.target.value); setOpen(true); if (!e.target.value) onChange('') }}
        onFocus={(e) => { e.target.select(); setOpen(true) }}
        onKeyDown={onKeyDown}
      />
      {onBrowse && (
        <button type="button" className="combo-browse" tabIndex={-1} disabled={disabled} title="Browse all products (F4)" aria-label="Browse all"
          onMouseDown={(e) => e.preventDefault()} onClick={() => { setOpen(false); onBrowse() }}>
          <Icon name="list" size={15} />
        </button>
      )}
      {open && pos && createPortal(
        <div ref={list} className="combo-pop" role="listbox"
          style={{ left: pos.left, width: pos.width, maxHeight: pos.maxHeight, ...(pos.up ? { bottom: window.innerHeight - pos.top } : { top: pos.top }) }}>
          {matches.length === 0 && <div className="combo-empty">{emptyText ?? 'No match'}</div>}
          {matches.map((o, i) => (
            <div key={o.value} role="option" aria-selected={o.value === value} data-active={i === active}
              className={`combo-opt ${i === active ? 'active' : ''}`}
              onMouseEnter={() => setActive(i)} onMouseDown={(e) => { e.preventDefault(); pick(o) }}>
              {o.render ?? o.label}
            </div>
          ))}
          {onBrowse && (
            <div className="combo-foot" onMouseDown={(e) => { e.preventDefault(); setOpen(false); onBrowse() }}>
              <Icon name="list" size={14} /> See all {options.length} in a full window <kbd className="kbd">F4</kbd>
            </div>
          )}
        </div>,
        document.body,
      )}
    </div>
  )
}
