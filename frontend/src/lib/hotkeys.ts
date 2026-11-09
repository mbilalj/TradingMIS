import { useEffect, useRef } from 'react'

export type HotkeyHandler = (e: KeyboardEvent) => void

/** True while the user is typing into a form control, where plain letter shortcuts must not fire. */
export function isTyping(t: EventTarget | null): boolean {
  const el = t as HTMLElement | null
  if (!el || !el.tagName) return false
  return el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.tagName === 'SELECT' || el.isContentEditable
}

/** "ctrl+s", "alt+n", "delete", "shift+/" — modifiers in the fixed order ctrl, alt, shift. */
export function comboOf(e: KeyboardEvent): string {
  const parts: string[] = []
  if (e.ctrlKey || e.metaKey) parts.push('ctrl')
  if (e.altKey) parts.push('alt')
  if (e.shiftKey) parts.push('shift')
  // With Alt held some layouts (macOS) produce a different character, so read the physical key for letters/digits.
  let key = e.key.toLowerCase()
  if (e.altKey && e.code) {
    if (e.code.startsWith('Key')) key = e.code.slice(3).toLowerCase()
    else if (e.code.startsWith('Digit')) key = e.code.slice(5)
  }
  if (key === ' ') key = 'space'
  if (key === 'esc') key = 'escape'
  if (!['control', 'alt', 'shift', 'meta'].includes(key)) parts.push(key)
  return parts.join('+')
}

export const modalOpen = () => document.querySelector('.overlay') !== null

/**
 * Registers keyboard shortcuts for as long as the component is mounted.
 * - Combos with ctrl/alt fire even while typing; plain keys (e.g. "/", "delete") only when not in a form control.
 * - Page shortcuts are paused while a dialog is open; pass { modal: true } for a dialog's own shortcuts.
 */
export function useHotkeys(map: Record<string, HotkeyHandler | undefined>, opts: { enabled?: boolean; modal?: boolean } = {}) {
  const ref = useRef(map)
  useEffect(() => { ref.current = map })
  const enabled = opts.enabled ?? true
  const modal = opts.modal ?? false

  useEffect(() => {
    if (!enabled) return
    const onKey = (e: KeyboardEvent) => {
      if (e.defaultPrevented || e.isComposing) return
      const combo = comboOf(e)
      const fn = ref.current[combo]
      if (!fn) return
      if (!modal && modalOpen()) return
      const hasModifier = combo.startsWith('ctrl') || combo.startsWith('alt') || /^f\d+$/.test(combo) || combo === 'escape'
      if (!hasModifier && isTyping(e.target)) return
      e.preventDefault()
      fn(e)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [enabled, modal])
}
