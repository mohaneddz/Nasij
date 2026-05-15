import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ShieldCheck, Eye, EyeOff, Loader2 } from 'lucide-react'
import { useAuth } from '../hooks/useAuth'

export default function LoginPage() {
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [showPwd, setShowPwd] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  
  const { signIn } = useAuth()
  const navigate = useNavigate()

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    
    try {
      await signIn(phone, password)
      navigate('/')
    } catch (err) {
      setError(err.message.includes('401') ? 'Identifiants invalides' : err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      className="min-h-screen flex items-center justify-center px-4"
      style={{
        background: 'var(--bg-base)',
      }}
    >
      <div
        className="w-full max-w-[380px] rounded-2xl p-7"
        style={{
          background: 'var(--bg-glass-heavy)',
          backdropFilter: 'blur(20px)',
          border: '1px solid var(--border-default)',
          boxShadow: '0 24px 80px rgba(0,0,0,0.4)',
        }}
      >
        {/* Logo */}
        <div className="flex flex-col items-center gap-3 mb-7">
          <div
            className="grid h-12 w-12 place-items-center rounded-xl"
            style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-default)' }}
          >
            <ShieldCheck className="h-6 w-6" style={{ color: 'var(--text-secondary)' }} strokeWidth={2.25} />
          </div>
          <div className="text-center">
            <h1
              className="text-3xl font-bold tracking-tight"
              style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
            >
              نسيج
            </h1>
            <p className="mt-1 text-[12px]" style={{ color: 'var(--text-muted)' }}>
              NFN Control Tower Authentication
            </p>
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 rounded-lg text-xs font-medium bg-red-500/10 border border-red-500/20 text-red-500 text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-4">
          <div className="space-y-1.5">
            <label className="text-[11px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
              Telephone ou E-mail
            </label>
            <input
              type="text"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              required
              placeholder="0770112233 ou 0770112233@nfn.local"
              className="w-full rounded-lg px-3.5 py-2.5 text-sm font-medium outline-none transition-all duration-200"
              style={{
                background: 'var(--bg-surface)',
                border: '1px solid var(--border-default)',
                color: 'var(--text-primary)',
              }}
              onFocus={(e) => { e.target.style.borderColor = 'var(--border-focus)'; e.target.style.boxShadow = '0 0 0 3px rgba(148,163,184,0.08)' }}
              onBlur={(e) => { e.target.style.borderColor = 'var(--border-default)'; e.target.style.boxShadow = 'none' }}
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-[11px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
              Mot de passe
            </label>
            <div className="relative">
              <input
                type={showPwd ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                placeholder="••••••••"
                className="w-full rounded-lg px-3.5 py-2.5 pr-10 text-sm font-medium outline-none transition-all duration-200"
                style={{
                  background: 'var(--bg-surface)',
                  border: '1px solid var(--border-default)',
                  color: 'var(--text-primary)',
                }}
                onFocus={(e) => { e.target.style.borderColor = 'var(--border-focus)'; e.target.style.boxShadow = '0 0 0 3px rgba(148,163,184,0.08)' }}
                onBlur={(e) => { e.target.style.borderColor = 'var(--border-default)'; e.target.style.boxShadow = 'none' }}
              />
              <button
                type="button"
                onClick={() => setShowPwd(!showPwd)}
                className="absolute right-3 top-1/2 -translate-y-1/2"
              >
                {showPwd ? (
                  <EyeOff className="h-4 w-4" style={{ color: 'var(--text-muted)' }} />
                ) : (
                  <Eye className="h-4 w-4" style={{ color: 'var(--text-muted)' }} />
                )}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-lg py-2.5 text-[13px] font-semibold transition-all duration-200 mt-2 flex items-center justify-center gap-2"
            style={{
              background: 'var(--text-primary)',
              color: 'var(--bg-base)',
              boxShadow: 'none',
              border: '1px solid var(--text-primary)',
              opacity: loading ? 0.7 : 1,
              cursor: loading ? 'not-allowed' : 'pointer'
            }}
          >
            {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Connexion Securisee'}
          </button>
        </form>

        <p className="mt-5 text-center text-[11px]" style={{ color: 'var(--text-muted)' }}>
          Entrez vos identifiants NFN Administrateur.
        </p>
      </div>
    </div>
  )
}


