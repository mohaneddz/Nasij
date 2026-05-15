import { useOutletContext } from 'react-router-dom'
import { AlertOctagon, CircleDot, ShieldAlert } from 'lucide-react'

export default function AlertsPage() {
  const { alerts } = useOutletContext()

  return (
    <div
      className="rounded-xl"
      style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}
    >
      {/* Header */}
      <div className="flex items-center gap-3 px-6 py-5" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
        <div
          className="grid h-9 w-9 place-items-center rounded-lg"
          style={{ background: 'var(--accent-rose-muted)', border: '1px solid rgba(239,68,68,0.22)' }}
        >
          <ShieldAlert className="h-4 w-4" style={{ color: 'var(--accent-rose)' }} strokeWidth={2.25} />
        </div>
        <div>
          <h2
            className="text-base font-semibold"
            style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
          >
            Centre de Controle (A1/E1)
          </h2>
          <p className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
            Gestion des points d'anomalie signales par le reseau.
          </p>
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr style={{ borderBottom: '1px solid var(--border-default)' }}>
              <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                Severite
              </th>
              <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                Type
              </th>
              <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                Lot / Contact
              </th>
              <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                Description
              </th>
              <th className="px-6 py-3.5 text-right text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
                Action
              </th>
            </tr>
          </thead>
          <tbody>
            {alerts.length > 0 ? (
              alerts.map((item, index) => {
                const isNoir = item.severity === 'POINT_NOIR'
                const isJaune = item.severity === 'POINT_JAUNE'
                const accent = isJaune ? 'var(--accent-amber)' : 'var(--accent-rose)'
                const muted = isJaune ? 'var(--accent-amber-muted)' : 'var(--accent-rose-muted)'
                const border = isJaune ? 'rgba(240,180,91,0.22)' : 'rgba(239,68,68,0.2)'
                return (
                  <tr
                    key={item.id}
                    className="transition-colors duration-150"
                    style={{
                      borderBottom: index < alerts.length - 1 ? '1px solid var(--border-subtle)' : 'none',
                      background: index % 2 === 1 ? 'var(--bg-raised)' : 'transparent',
                    }}
                    onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(148,163,184,0.04)' }}
                    onMouseLeave={(e) => { e.currentTarget.style.background = index % 2 === 1 ? 'var(--bg-raised)' : 'transparent' }}
                  >
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-2">
                        {isNoir ? (
                          <CircleDot className="h-4 w-4 shrink-0" style={{ color: 'var(--text-primary)' }} strokeWidth={2.25} />
                        ) : isJaune ? (
                          <AlertOctagon className="h-4 w-4 shrink-0" style={{ color: accent }} strokeWidth={2.25} />
                        ) : (
                          <AlertOctagon className="h-4 w-4 shrink-0 pulse-rose" style={{ color: accent }} strokeWidth={2.25} />
                        )}
                        <span
                          className="text-[13px] font-semibold"
                          style={{ color: isNoir ? 'var(--text-primary)' : accent }}
                        >
                          {isNoir ? 'Point Noir' : isJaune ? 'Point Jaune' : 'Point Rouge'}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className="rounded-md px-2 py-1 text-[11px] font-bold"
                        style={{
                          background: isNoir ? 'var(--bg-raised)' : muted,
                          color: isNoir ? 'var(--text-secondary)' : accent,
                          border: `1px solid ${isNoir ? 'var(--border-default)' : border}`,
                        }}
                      >
                        {item.alertType}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="text-[12px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                        {item.batchMeta?.batchId || item.batchId}
                      </div>
                      <div className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
                        {item.batchMeta?.wilaya || '—'} · {item.batchMeta?.sourceType || '—'}
                      </div>
                      <div className="mt-1 text-[11px]" style={{ color: 'var(--text-secondary)' }}>
                        {item.batchMeta?.creator?.phoneNumber ? `C1/C2/C3: ${item.batchMeta.creator.phoneNumber}` : null}
                        {item.batchMeta?.creator?.phoneNumber && item.batchMeta?.collector?.phoneNumber ? ' · ' : null}
                        {item.batchMeta?.collector?.phoneNumber ? `Collecteur: ${item.batchMeta.collector.phoneNumber}` : null}
                        {!item.batchMeta?.creator?.phoneNumber && !item.batchMeta?.collector?.phoneNumber ? 'Contact indisponible' : null}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-[13px] font-medium leading-relaxed" style={{ color: 'var(--text-secondary)' }}>
                        {item.description}
                      </p>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        type="button"
                        className="rounded-md px-3 py-1.5 text-[12px] font-semibold transition-colors duration-200"
                        style={{
                          background: isNoir ? 'var(--bg-raised)' : muted,
                          color: isNoir ? 'var(--text-secondary)' : accent,
                          border: `1px solid ${isNoir ? 'var(--border-default)' : border}`,
                        }}
                      >
                        {item.action}
                      </button>
                    </td>
                  </tr>
                )
              })
            ) : (
              <tr>
                <td colSpan={5} className="px-6 py-12 text-center">
                  <p className="text-sm font-medium" style={{ color: 'var(--text-muted)' }}>
                    Aucune alerte active. Tout est operationnel.
                  </p>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
