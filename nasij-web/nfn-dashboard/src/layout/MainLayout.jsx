import {
  AlertTriangle,
  BarChart3,
  Brain,
  ChevronRight,
  LayoutDashboard,
  LogOut,
  MapPinned,
  Menu,
  Moon,
  RefreshCw,
  ScrollText,
  ShieldCheck,
  Sun,
  Wifi,
  WifiOff,
  X,
} from 'lucide-react'
import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { useDashboardData } from '../hooks/useDashboardData'
import { useEffect, useState } from 'react'
import logo from '../assets/logo.png'

const navItems = [
  { path: '/', label: 'Tableau de Bord', icon: LayoutDashboard },
  { path: '/map', label: 'Cartographie Live', icon: MapPinned },
  { path: '/pipeline', label: 'Flux & Stockage', icon: RefreshCw },
  { path: '/users', label: 'Gestion des Utilisateurs', icon: ScrollText },
  { path: '/alerts', label: 'Alertes & Fraudes', icon: AlertTriangle },
  { path: '/certification', label: 'Sceau NFN', icon: ScrollText },
  { path: '/ai', label: 'Intelligence IA', icon: Brain },
]

const pageTitles = {
  '/': 'Tableau de Bord',
  '/map': 'Cartographie Live',
  '/pipeline': 'Flux & Stockage',
  '/users': 'Gestion des Utilisateurs',
  '/alerts': 'Centre de Controle',
  '/certification': 'Sceau de Certification',
  '/ai': 'Intelligence Artificielle',
}

export default function MainLayout({ onLogout }) {
  const { batches, alerts, loading, error, source } = useDashboardData()
  const live = source === 'supabase-live' || source === 'backend-live'
  const location = useLocation()
  const [mobileOpen, setMobileOpen] = useState(false)

  const pageTitle = pageTitles[location.pathname] || 'نسيج'

  const [theme, setTheme] = useState(() => localStorage.getItem('nfn-theme') || 'light')
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('nfn-theme', theme)
  }, [theme])
  const toggleTheme = () => setTheme((t) => (t === 'dark' ? 'light' : 'dark'))

  return (
    <div className="min-h-screen topo-bg" style={{ background: 'var(--bg-base)' }}>
      {/* ---- SIDEBAR (DESKTOP) ---- */}
      <aside
        className="fixed inset-y-0 left-0 z-30 hidden w-[280px] flex-col lg:flex"
        style={{
          background: 'var(--bg-glass-heavy)',
          backdropFilter: 'blur(20px)',
          borderRight: '1px solid var(--border-subtle)',
        }}
      >
        {/* Brand */}
        <div className="px-6 py-6" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
          <div className="flex items-center">
            <img src={logo} alt="NFN Logo" className="h-12 w-auto object-contain" />
          </div>
          <div className="mt-5 flex h-[3px] w-full overflow-hidden rounded-full" style={{ background: 'var(--border-subtle)' }}>
            <div className="w-full" style={{ background: 'var(--border-strong)' }} />
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-4 py-5 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon
            return (
              <NavLink
                key={item.path}
                to={item.path}
                end={item.path === '/'}
                className={({ isActive }) =>
                  [
                    'group flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-medium transition-all duration-200',
                    isActive ? '' : '',
                  ].join(' ')
                }
                style={({ isActive }) => ({
                  color: isActive ? 'var(--text-primary)' : 'var(--text-secondary)',
                  background: isActive ? 'var(--bg-raised)' : 'transparent',
                  borderLeft: isActive ? '2px solid var(--border-strong)' : '2px solid transparent',
                })}
              >
                <Icon className="h-[18px] w-[18px] shrink-0" strokeWidth={2} />
                <span className="truncate">{item.label}</span>
              </NavLink>
            )
          })}
        </nav>

        {/* Footer */}
        <div className="px-4 pb-5">

          <button
            type="button"
            onClick={onLogout}
            className="mt-3 flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-medium transition-colors duration-200 hover:bg-white/[0.04]"
            style={{ color: 'var(--text-muted)' }}
          >
            <LogOut className="h-4 w-4" />
            Deconnexion
          </button>
        </div>
      </aside>

      {/* ---- MOBILE HEADER ---- */}
      <div
        className="fixed inset-x-0 top-0 z-20 flex items-center justify-between px-4 py-3 lg:hidden"
        style={{ background: 'var(--bg-glass-heavy)', backdropFilter: 'blur(16px)', borderBottom: '1px solid var(--border-subtle)' }}
      >
        <div className="flex items-center gap-2.5">
          <img src={logo} alt="NFN Logo" className="h-8 w-auto object-contain" />
        </div>
        <button
          type="button"
          onClick={() => setMobileOpen(!mobileOpen)}
          className="grid h-9 w-9 place-items-center rounded-lg"
          style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-default)' }}
        >
          {mobileOpen ? <X className="h-4 w-4" style={{ color: 'var(--text-primary)' }} /> : <Menu className="h-4 w-4" style={{ color: 'var(--text-primary)' }} />}
        </button>
      </div>

      {/* ---- MOBILE DRAWER ---- */}
      {mobileOpen && (
        <div className="fixed inset-0 z-40 lg:hidden" onClick={() => setMobileOpen(false)}>
          <div className="absolute inset-0" style={{ background: 'rgba(0,0,0,0.6)' }} />
          <aside
            className="absolute inset-y-0 left-0 w-72 flex flex-col"
            style={{ background: 'var(--bg-surface)', borderRight: '1px solid var(--border-default)' }}
            onClick={(e) => e.stopPropagation()}
          >
            <div className="px-5 py-5" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
              <div className="flex items-center gap-3">
                <img src={logo} alt="NFN Logo" className="h-8 w-auto object-contain" />
              </div>
            </div>
            <nav className="flex-1 px-3 py-4 space-y-1">
              {navItems.map((item) => {
                const Icon = item.icon
                return (
                  <NavLink
                    key={item.path}
                    to={item.path}
                    end={item.path === '/'}
                    onClick={() => setMobileOpen(false)}
                    className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-[13px] font-medium"
                    style={({ isActive }) => ({
                      color: isActive ? 'var(--text-primary)' : 'var(--text-secondary)',
                      background: isActive ? 'var(--bg-raised)' : 'transparent',
                    })}
                  >
                    <Icon className="h-[18px] w-[18px]" strokeWidth={2} />
                    <span>{item.label}</span>
                  </NavLink>
                )
              })}
            </nav>
          </aside>
        </div>
      )}

      {/* ---- MAIN CONTENT ---- */}
      <main className="min-h-screen pt-14 lg:pt-0 lg:pl-[280px]">
        <div className="mx-auto max-w-[1520px] px-5 py-5 sm:px-7 lg:py-6">
          {/* Page header */}
          <header className="mb-4 lg:mb-6 flex items-start justify-between gap-4">
            <div>
              <div
                className="inline-flex items-center gap-2 rounded-md px-2 py-1 lg:px-2.5 lg:py-1.5 text-[10px] font-semibold uppercase tracking-[0.1em]"
                style={{ background: 'var(--bg-raised)', color: 'var(--text-secondary)', border: '1px solid var(--border-subtle)' }}
              >
                <BarChart3 className="h-3 w-3" />
                Ministere de l'Agriculture
              </div>
              <h1
                className="mt-2 lg:mt-3 text-2xl lg:text-[28px] font-semibold leading-tight tracking-tight"
                style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
              >
                {pageTitle}
              </h1>
              <p className="mt-1 lg:mt-1.5 hidden sm:block max-w-xl text-sm" style={{ color: 'var(--text-muted)', lineHeight: '1.7' }}>
                Supervision nationale de la filiere laine — reseau NFN.
              </p>
            </div>
              <div className="flex items-center gap-2">
                {error && (
                  <div
                    className="rounded-md px-3 py-1.5 text-xs font-medium"
                    style={{ background: 'var(--bg-raised)', color: 'var(--text-secondary)', border: '1px solid var(--border-default)' }}
                  >
                    Mode mock
                  </div>
                )}
                <button
                  type="button"
                  onClick={toggleTheme}
                  className="grid h-9 w-9 place-items-center rounded-lg transition-colors duration-200"
                  style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-default)' }}
                  title={theme === 'dark' ? 'Mode clair' : 'Mode sombre'}
                >
                  {theme === 'dark'
                    ? <Sun className="h-4 w-4" style={{ color: 'var(--text-secondary)' }} />
                    : <Moon className="h-4 w-4" style={{ color: 'var(--text-secondary)' }} />
                  }
                </button>
              </div>
          </header>

          <div className="page-enter">
            <Outlet context={{ batches, alerts }} />
          </div>
        </div>
      </main>
    </div>
  )
}
