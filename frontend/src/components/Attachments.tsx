import { useRef } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Api } from '../api/resources'
import { api, apiErrorMessage } from '../api/client'
import { useAuth } from '../auth/AuthContext'
import { isOwner } from '../auth/access'
import { fmtDate } from '../lib/format'
import Icon from './Icon'
import { useToast } from './Toast'

async function download(id: number, name: string) {
  const res = await api.get(`/attachments/${id}/download`, { responseType: 'blob' })
  const url = URL.createObjectURL(res.data)
  const a = document.createElement('a')
  a.href = url
  a.download = name
  a.click()
  URL.revokeObjectURL(url)
}

/** Supporting documents for a shipment / expense. */
export default function Attachments({ ownerType, ownerId, canUpload = true }: { ownerType: string; ownerId: number; canUpload?: boolean }) {
  const qc = useQueryClient()
  const toast = useToast()
  const { user } = useAuth()
  const input = useRef<HTMLInputElement>(null)
  const list = useQuery({ queryKey: ['attachments', ownerType, ownerId], queryFn: () => Api.attachments(ownerType, ownerId) })

  const upload = useMutation({
    mutationFn: (file: File) => Api.upload(ownerType, ownerId, file),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['attachments', ownerType, ownerId] }); toast.ok('Document attached') },
    onError: (e) => toast.err(apiErrorMessage(e)),
  })
  const remove = useMutation({
    mutationFn: (id: number) => Api.deleteAttachment(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['attachments', ownerType, ownerId] }),
    onError: (e) => toast.err(apiErrorMessage(e)),
  })

  return (
    <div>
      {(list.data ?? []).length === 0 && <div className="muted" style={{ padding: '6px 0' }}>No documents attached.</div>}
      <div style={{ display: 'grid', gap: 8 }}>
        {(list.data ?? []).map((a) => (
          <div key={a.id} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', border: '1px solid var(--line)', borderRadius: 10 }}>
            <Icon name="file" size={18} />
            <button className="btn btn-ghost btn-sm" style={{ padding: 0, height: 'auto', fontWeight: 600, color: 'var(--primary)' }} onClick={() => download(a.id, a.fileName)}>{a.fileName}</button>
            <span className="muted" style={{ fontSize: 12 }}>{(a.size / 1024).toFixed(0)} KB · {fmtDate(a.uploadedAt?.slice(0, 10))}</span>
            {isOwner(user?.role) && <button className="btn btn-ghost btn-sm btn-icon" style={{ marginLeft: 'auto' }} onClick={() => remove.mutate(a.id)} aria-label="Remove"><Icon name="trash" size={15} /></button>}
          </div>
        ))}
      </div>
      {canUpload && (
        <>
          <input ref={input} type="file" hidden onChange={(e) => { const f = e.target.files?.[0]; if (f) upload.mutate(f); e.target.value = '' }} />
          <button className="btn btn-secondary btn-sm" style={{ marginTop: 10 }} onClick={() => input.current?.click()} disabled={upload.isPending}>
            <Icon name="clip" size={15} /> {upload.isPending ? 'Uploading…' : 'Attach document'}
          </button>
        </>
      )}
    </div>
  )
}
