import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import Icon from '../components/Icon'
import { BrandLockup, PoweredBy } from '../components/Brand'

const POINTS = [
  { icon: 'layers' as const, title: 'Batch-accurate stock', text: 'Every unit is traced to the shipment it arrived in, at the cost you entered.' },
  { icon: 'cart' as const, title: 'Wholesale & retail in one flow', text: 'Invoice, stock, payment, ledger and profit are posted together — never typed twice.' },
  { icon: 'scale' as const, title: 'Honest profit & loss', text: 'Operating expenses reduce profit; customs and shipment payments only move cash and bank.' },
]

export default function LoginPage() {
  const { login } = useAuth()
  const navigate = useNavigate()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    setError(null)
    try {
      await login(username, password)
      navigate('/')
    } catch {
      setError('Invalid username or password.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="login-wrap">
      <div className="login-hero">
        <div style={{ position: 'relative', zIndex: 1 }}><BrandLockup size={48} dark /></div>
        <div style={{ position: 'relative', zIndex: 1, maxWidth: 520 }}>
          <h1 style={{ fontSize: 40, fontWeight: 780, lineHeight: 1.1, letterSpacing: '-0.03em', marginBottom: 18 }}>
            From warehouse door to the last rupee.
          </h1>
          <p style={{ color: '#b6c2dc', fontSize: 16, marginBottom: 34 }}>
            Stock, sales, customers, suppliers, cash and accounts — one connected system for everything after goods arrive in Lahore.
          </p>
          <div style={{ display: 'grid', gap: 18 }}>
            {POINTS.map((p) => (
              <div key={p.title} style={{ display: 'flex', gap: 14 }}>
                <div style={{ width: 38, height: 38, borderRadius: 10, background: 'rgba(255,255,255,.1)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
                  <Icon name={p.icon} size={19} />
                </div>
                <div>
                  <div style={{ fontWeight: 680 }}>{p.title}</div>
                  <div style={{ color: '#9fb0d0', fontSize: 13.5 }}>{p.text}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
        <div style={{ color: '#7384a8', fontSize: 12.5, position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
          <span>© {new Date().getFullYear()} Portside Trading</span>
          <PoweredBy dark size={12.5} />
        </div>
      </div>

      <div className="login-form-wrap">
        <form onSubmit={onSubmit} style={{ width: '100%', maxWidth: 380 }}>
          <div className="kicker" style={{ marginBottom: 6 }}>Welcome back</div>
          <h2 style={{ fontSize: 28, fontWeight: 760, letterSpacing: '-0.02em', marginBottom: 6 }}>Sign in</h2>
          <p className="muted" style={{ marginTop: 0, marginBottom: 26 }}>Use your company account to continue.</p>

          <label className="field" style={{ marginBottom: 16 }}>
            <span className="lbl">Username</span>
            <input className="input" style={{ height: 42 }} value={username} onChange={(e) => setUsername(e.target.value)} autoFocus autoComplete="username" />
          </label>
          <label className="field" style={{ marginBottom: 20 }}>
            <span className="lbl">Password</span>
            <input className="input" style={{ height: 42 }} type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
          </label>

          {error && <div className="banner danger" style={{ marginBottom: 16 }}>{error}</div>}

          <button className="btn btn-primary" style={{ width: '100%', height: 44, fontSize: 14.5 }} disabled={busy || !username || !password}>
            {busy ? 'Signing in…' : 'Sign in'}
          </button>

          <p className="muted" style={{ fontSize: 12.5, marginTop: 22 }}>
            Demo accounts: <code>owner</code> <code>accountant</code> <code>sales</code> <code>storekeeper</code> <code>importdesk</code> · password <code>Portside@123</code>
          </p>
          <div style={{ marginTop: 30 }}><PoweredBy size={12} /></div>
        </form>
      </div>
    </div>
  )
}
