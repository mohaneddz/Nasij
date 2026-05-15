import React, { useState, useEffect } from 'react';
import { UserPlus, UserCheck, Search, PlusCircle, CheckCircle, ShieldCheck } from 'lucide-react';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const UsersManagementPage = () => {
  const [activeTab, setActiveTab] = useState('create'); // 'create' or 'approve'
  
  // Create Staff State
  const [formData, setFormData] = useState({
    phone: '',
    password: '',
    full_name: '',
    sector: 'DEPOT_WORKER',
    wilaya: ''
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [createMessage, setCreateMessage] = useState({ type: '', text: '' });

  // Pending Approvals State
  const [pendingUsers, setPendingUsers] = useState([]);
  const [isLoadingPending, setIsLoadingPending] = useState(false);

  useEffect(() => {
    if (activeTab === 'approve') {
      fetchPendingUsers();
    }
  }, [activeTab]);

  const fetchPendingUsers = async () => {
    setIsLoadingPending(true);
    try {
      const response = await fetch(`${API_URL}/api/users/pending`);
      if (!response.ok) throw new Error('Failed to fetch pending users');
      const data = await response.json();
      setPendingUsers(data);
    } catch (error) {
      console.error(error);
    } finally {
      setIsLoadingPending(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleCreateStaff = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setCreateMessage({ type: '', text: '' });

    try {
      const response = await fetch(`${API_URL}/api/users/staff`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      if (!response.ok) {
        const err = await response.json();
        const detail = err.detail;
        let msg = 'Failed to create user';
        if (typeof detail === 'string') {
          msg = detail;
        } else if (Array.isArray(detail)) {
          msg = detail.map(d => d.msg || JSON.stringify(d)).join(', ');
        }
        throw new Error(msg);
      }

      setCreateMessage({ type: 'success', text: 'Compte employe cree avec succes.' });
      setFormData({ phone: '', password: '', full_name: '', sector: 'DEPOT_WORKER', wilaya: '' });
    } catch (error) {
      setCreateMessage({ type: 'error', text: error.message });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleApproveUser = async (userId) => {
    try {
      const response = await fetch(`${API_URL}/api/users/${userId}/approve`, {
        method: 'PATCH',
      });
      
      if (!response.ok) throw new Error('Failed to approve user');
      
      // Remove from list
      setPendingUsers(prev => prev.filter(u => u.id !== userId));
    } catch (error) {
      alert(`Error: ${error.message}`);
    }
  };

  // Common input styles
  const inputStyle = {
    background: 'var(--bg-base)',
    border: '1px solid var(--border-strong)',
    color: 'var(--text-primary)'
  };

  return (
    <div className="space-y-6">
      {/* Top Nav Tabs */}
      <div style={{ borderBottom: '1px solid var(--border-default)' }}>
        <nav className="-mb-px flex space-x-8" aria-label="Tabs">
          <button
            onClick={() => setActiveTab('create')}
            className={`flex items-center whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors`}
            style={{
              borderColor: activeTab === 'create' ? 'var(--text-primary)' : 'transparent',
              color: activeTab === 'create' ? 'var(--text-primary)' : 'var(--text-muted)'
            }}
          >
            <UserPlus className="mr-2 h-4 w-4" />
            Nouveau Staff
          </button>
          <button
            onClick={() => setActiveTab('approve')}
            className={`flex items-center whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors`}
            style={{
              borderColor: activeTab === 'approve' ? 'var(--text-primary)' : 'transparent',
              color: activeTab === 'approve' ? 'var(--text-primary)' : 'var(--text-muted)'
            }}
          >
            <UserCheck className="mr-2 h-4 w-4" />
            Comptes en Attente
            {pendingUsers.length > 0 && activeTab === 'create' && (
               <span 
                 className="ml-2 py-0.5 px-2 rounded-full text-[10px] font-bold"
                 style={{ background: 'var(--accent-rose-muted)', color: 'var(--accent-rose)' }}
               >
                 Nouveau
               </span>
            )}
          </button>
        </nav>
      </div>

      {activeTab === 'create' && (
        <div className="rounded-xl p-6 max-w-2xl" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
          <h2 className="text-base font-semibold mb-6 flex items-center" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
            <PlusCircle className="mr-2 h-5 w-5" style={{ color: 'var(--accent-emerald)' }} />
            Creation de Compte Staff
          </h2>
          
          {createMessage.text && (
            <div 
              className="mb-6 p-4 rounded-md text-sm font-medium" 
              style={{ 
                background: createMessage.type === 'success' ? 'var(--accent-emerald-muted)' : 'var(--accent-rose-muted)', 
                color: createMessage.type === 'success' ? 'var(--accent-emerald)' : 'var(--accent-rose)',
                border: `1px solid ${createMessage.type === 'success' ? 'rgba(143, 189, 164, 0.2)' : 'rgba(239, 68, 68, 0.2)'}`
              }}
            >
              {createMessage.text}
            </div>
          )}

          <form onSubmit={handleCreateStaff} className="space-y-5">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div>
                <label className="block text-xs font-semibold uppercase tracking-[0.1em] mb-1.5" style={{ color: 'var(--text-muted)' }}>Nom Complet</label>
                <input
                  type="text"
                  name="full_name"
                  required
                  value={formData.full_name}
                  onChange={handleInputChange}
                  className="block w-full rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-white/20 transition-all"
                  style={inputStyle}
                  placeholder="Ex: Ahmed Benali"
                />
              </div>
              
              <div>
                <label className="block text-xs font-semibold uppercase tracking-[0.1em] mb-1.5" style={{ color: 'var(--text-muted)' }}>Telephone</label>
                <input
                  type="text"
                  name="phone"
                  required
                  value={formData.phone}
                  onChange={handleInputChange}
                  className="block w-full rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-white/20 transition-all"
                  style={inputStyle}
                  placeholder="05..."
                />
              </div>
              
              <div>
                <label className="block text-xs font-semibold uppercase tracking-[0.1em] mb-1.5" style={{ color: 'var(--text-muted)' }}>Mot de passe</label>
                <input
                  type="password"
                  name="password"
                  required
                  minLength="6"
                  value={formData.password}
                  onChange={handleInputChange}
                  className="block w-full rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-white/20 transition-all"
                  style={inputStyle}
                  placeholder="••••••••"
                />
              </div>
              
              <div>
                <label className="block text-xs font-semibold uppercase tracking-[0.1em] mb-1.5" style={{ color: 'var(--text-muted)' }}>Wilaya (Optionnel)</label>
                <input
                  type="text"
                  name="wilaya"
                  value={formData.wilaya}
                  onChange={handleInputChange}
                  className="block w-full rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-white/20 transition-all"
                  style={inputStyle}
                  placeholder="Ex: Djelfa"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-xs font-semibold uppercase tracking-[0.1em] mb-1.5" style={{ color: 'var(--text-muted)' }}>Role / Secteur</label>
                <select
                  name="sector"
                  value={formData.sector}
                  onChange={handleInputChange}
                  className="block w-full rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-white/20 transition-all"
                  style={inputStyle}
                >
                  <option value="DEPOT_WORKER">Depot Worker</option>
                  <option value="LAVAGE_WORKER">Lavarie Worker</option>
                  <option value="COLLECTOR">Collector</option>
                  <option value="TRANSFORMATEUR">Transformateur</option>
                </select>
                <p className="mt-2 text-[11px]" style={{ color: 'var(--text-muted)' }}>
                  Assignez ces roles pour le personnel interne du reseau NFN.
                </p>
              </div>
            </div>

            <div className="pt-4 border-t" style={{ borderColor: 'var(--border-subtle)' }}>
              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full md:w-auto inline-flex justify-center items-center py-2 px-6 rounded-md text-[13px] font-semibold transition-colors duration-200 disabled:opacity-50"
                style={{ 
                  background: 'var(--text-primary)', 
                  color: 'var(--bg-base)',
                }}
              >
                {isSubmitting ? 'Creation...' : 'Creer le compte'}
              </button>
            </div>
          </form>
        </div>
      )}

      {activeTab === 'approve' && (
        <div className="rounded-xl overflow-hidden" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
          {/* Header */}
          <div className="flex items-center gap-3 px-6 py-5" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
            <div
              className="grid h-9 w-9 place-items-center rounded-lg"
              style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-strong)' }}
            >
              <ShieldCheck className="h-4 w-4" style={{ color: 'var(--text-primary)' }} strokeWidth={2.25} />
            </div>
            <div>
              <h2 className="text-base font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
                Comptes en Attente
              </h2>
              <p className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
                Validation requise pour les acces C1, C2 et C3.
              </p>
            </div>
          </div>

          {isLoadingPending ? (
            <div className="p-12 text-center text-[13px] font-medium" style={{ color: 'var(--text-muted)' }}>Chargement des comptes...</div>
          ) : pendingUsers.length === 0 ? (
            <div className="p-12 text-center">
              <CheckCircle className="mx-auto h-10 w-10 mb-3" style={{ color: 'var(--accent-emerald)' }} strokeWidth={1.5} />
              <h3 className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>Aucune validation en attente</h3>
              <p className="mt-1 text-[11px]" style={{ color: 'var(--text-muted)' }}>Le reseau est completement a jour.</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border-default)' }}>
                    <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                      Contact
                    </th>
                    <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                      Secteur
                    </th>
                    <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                      Localisation
                    </th>
                    <th className="px-6 py-3.5 text-right text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                      Action
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {pendingUsers.map((user, index) => (
                    <tr 
                      key={user.id} 
                      className="transition-colors duration-150"
                      style={{
                        borderBottom: index < pendingUsers.length - 1 ? '1px solid var(--border-subtle)' : 'none',
                        background: index % 2 === 1 ? 'var(--bg-raised)' : 'transparent',
                      }}
                      onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(148,163,184,0.04)' }}
                      onMouseLeave={(e) => { e.currentTarget.style.background = index % 2 === 1 ? 'var(--bg-raised)' : 'transparent' }}
                    >
                      <td className="px-6 py-4">
                        <div className="text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                          {user.full_name || 'Non renseigne'}
                        </div>
                        <div className="mt-0.5 text-[11px]" style={{ color: 'var(--text-secondary)' }}>
                          {user.phone_number}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span
                          className="rounded-md px-2 py-1 text-[11px] font-bold"
                          style={{
                            background: 'var(--bg-raised)',
                            color: 'var(--text-secondary)',
                            border: '1px solid var(--border-strong)',
                          }}
                        >
                          {user.sector}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-[12px] font-medium" style={{ color: 'var(--text-secondary)' }}>
                          {user.wilaya || '—'}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button
                          onClick={() => handleApproveUser(user.id)}
                          className="rounded-md px-4 py-1.5 text-[12px] font-semibold transition-colors duration-200 hover:opacity-80"
                          style={{
                            background: 'var(--text-primary)',
                            color: 'var(--bg-base)',
                          }}
                        >
                          Approuver
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default UsersManagementPage;
