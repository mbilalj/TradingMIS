import { useMutation, useQueryClient } from '@tanstack/react-query'
import { apiErrorMessage } from '../api/client'
import { useToast } from '../components/Toast'

/** Mutation with the app-wide conventions: success toast, error toast, refresh the named query keys. */
export function useAction<V, R>(
  fn: (v: V) => Promise<R>,
  opts: { ok?: string; invalidate?: string[]; onDone?: (r: R, v: V) => void; onFail?: (message: string, v: V) => void } = {},
) {
  const qc = useQueryClient()
  const toast = useToast()
  return useMutation({
    mutationFn: fn,
    onSuccess: (r, v) => {
      if (opts.ok) toast.ok(opts.ok)
      // Money-moving actions touch most screens, so refresh broadly unless told otherwise.
      const keys = opts.invalidate ?? ['dashboard', 'products', 'customers', 'suppliers', 'accounts', 'report', 'sales', 'shipments']
      keys.forEach((k) => qc.invalidateQueries({ queryKey: [k] }))
      opts.onDone?.(r, v)
    },
    onError: (e, v) => {
      const msg = apiErrorMessage(e)
      if (opts.onFail) opts.onFail(msg, v)
      else toast.err(msg)
    },
  })
}
