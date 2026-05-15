import { Navigate, Route, Routes } from 'react-router-dom'
import MainLayout from './layout/MainLayout'
import HomePage from './pages/HomePage'
import MapPage from './pages/MapPage'
import PipelinePage from './pages/PipelinePage'
import AlertsPage from './pages/AlertsPage'
import CertificationPage from './pages/CertificationPage'
import UsersManagementPage from './pages/UsersManagementPage'
import AIPage from './pages/AIPage'
import LoginPage from './pages/LoginPage'
import { AuthProvider, useAuth } from './hooks/useAuth'

function AppRoutes() {
  const { user, loading, signOut } = useAuth()

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center" style={{ background: 'var(--bg-base)', color: 'var(--text-primary)' }}>Loading...</div>
  }

  return (
    <Routes>
      <Route path="/login" element={!user ? <LoginPage /> : <Navigate to="/" replace />} />
      <Route path="/" element={user ? <MainLayout onLogout={signOut} /> : <Navigate to="/login" replace />}>
        <Route index element={<HomePage />} />
        <Route path="map" element={<MapPage />} />
        <Route path="pipeline" element={<PipelinePage />} />
        <Route path="users" element={<UsersManagementPage />} />
        <Route path="alerts" element={<AlertsPage />} />
        <Route path="certification" element={<CertificationPage />} />
        <Route path="ai" element={<AIPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  )
}
