/** Focus a cell in a line-entry grid: inputs carry data-r (row) and data-f (field). Runs after React has rendered. */
export function focusCell(row: number, field: string) {
  setTimeout(() => {
    const el = document.querySelector<HTMLInputElement>(`[data-r="${row}"][data-f="${field}"]`)
    el?.focus()
    el?.select?.()
  }, 30)
}

/** Enter in a grid cell moves to `next` instead of submitting. */
export function enterTo(next: () => void) {
  return (e: React.KeyboardEvent) => { if (e.key === 'Enter') { e.preventDefault(); next() } }
}
