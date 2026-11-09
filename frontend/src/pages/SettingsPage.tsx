import { useEffect, useState } from 'react'
import { Api } from '../api/resources'
import { useSettings } from '../api/hooks'
import { Card, Field, Kbd, Loading, PageHeader } from '../components/ui'
import { useHotkeys } from '../lib/hotkeys'
import { useAction } from '../lib/useAction'

const FIELDS: { key: string; label: string; span2?: boolean; hint?: string }[] = [
  { key: 'business.name', label: 'Business name' },
  { key: 'business.phone', label: 'Phone' },
  { key: 'business.address', label: 'Address', span2: true },
  { key: 'business.email', label: 'Email' },
  { key: 'business.taxNo', label: 'Tax / NTN number' },
  { key: 'invoice.footer', label: 'Invoice footer message', span2: true, hint: 'Printed at the bottom of every invoice.' },
]

export default function SettingsPage() {
  const settings = useSettings()
  const [values, setValues] = useState<Record<string, string>>({})
  useEffect(() => { if (settings.data) setValues(settings.data) }, [settings.data])
  const save = useAction(() => Api.saveSettings(values), { ok: 'Settings saved', invalidate: ['settings'] })
  useHotkeys({ 'ctrl+s': () => save.mutate(undefined) })
  if (settings.isLoading) return <Loading />

  return (
    <div>
      <PageHeader kicker="Admin" title="Settings" blurb="Business details that appear on every invoice and report."
        actions={<button className="btn btn-primary" disabled={save.isPending} onClick={() => save.mutate(undefined)}>{save.isPending ? 'Saving…' : 'Save settings'}<Kbd>Ctrl+S</Kbd></button>} />
      <Card title="Business profile">
        <div className="form-grid">
          {FIELDS.map((f) => (
            <Field key={f.key} label={f.label} span2={f.span2} hint={f.hint}>
              <input className="input" value={values[f.key] ?? ''} onChange={(e) => setValues((v) => ({ ...v, [f.key]: e.target.value }))} />
            </Field>
          ))}
        </div>
      </Card>
      <div style={{ height: 16 }} />
      <Card title="Books" sub="Opening balances are dated from here so they never distort a later profit & loss period.">
        <Field label="Books start date"><input className="input" type="date" style={{ maxWidth: 220 }} value={values['books.startDate'] ?? ''} onChange={(e) => setValues((v) => ({ ...v, 'books.startDate': e.target.value }))} /></Field>
      </Card>
    </div>
  )
}
