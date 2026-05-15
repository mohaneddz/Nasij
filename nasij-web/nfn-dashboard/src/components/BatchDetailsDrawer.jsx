import { X } from 'lucide-react'
import {
  breedLabels,
  getBatchAnnexDetails,
  sourceLabels,
  woolClassLabels,
  woolTypeLabels,
} from '../dashboardData'

function Row({ label, value, tone = 'neutral' }) {
  const color = tone === 'alert'
    ? 'var(--accent-rose)'
    : tone === 'warn'
      ? 'var(--accent-amber)'
      : 'var(--text-primary)'

  return (
    <div className="flex items-center justify-between gap-4 py-2">
      <span className="text-[11px] font-medium" style={{ color: 'var(--text-muted)' }}>{label}</span>
      <span className="text-[12px] font-semibold text-right tabular-nums" style={{ color }}>{value ?? '-'}</span>
    </div>
  )
}

function Section({ title, children }) {
  return (
    <section
      className="rounded-lg p-4"
      style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)' }}
    >
      <p className="mb-2 text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
        {title}
      </p>
      <div className="divide-y" style={{ borderColor: 'var(--border-subtle)' }}>
        {children}
      </div>
    </section>
  )
}

export default function BatchDetailsDrawer({ batch, onClose }) {
  if (!batch) return null

  const annex = getBatchAnnexDetails(batch)
  const hotPile = annex.temperatureTasCelsius >= 42
  const highVm = annex.tauxMatiereVegetalePercent > 5

  return (
    <div
      className="fixed inset-0"
      style={{ pointerEvents: 'none', zIndex: 1100 }}
      role="dialog"
      aria-modal="true"
    >
      <button
        type="button"
        aria-label="Fermer"
        className="absolute inset-0 h-full w-full cursor-default"
        style={{ background: 'rgba(0,0,0,0.35)', pointerEvents: 'auto' }}
        onClick={onClose}
      />
      <aside
        className="absolute right-0 top-0 flex h-full w-full max-w-[400px] flex-col p-5 shadow-2xl"
        style={{
          background: 'var(--bg-base)',
          borderLeft: '1px solid var(--border-default)',
          pointerEvents: 'auto',
          animation: 'slideInRight 0.25s ease-out',
          overflowY: 'auto',
        }}
      >
        <div className="mb-5 flex items-start justify-between gap-4">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.12em]" style={{ color: 'var(--accent-emerald)' }}>
              Fiche technique annex
            </p>
            <h2 className="mt-2 text-xl font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
              LOT {batch.batchId}
            </h2>
            <p className="mt-1 text-[12px]" style={{ color: 'var(--text-muted)' }}>
              Source: {sourceLabels[batch.sourceType] || batch.sourceType} | Race: {breedLabels[batch.breed] || batch.breed}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="grid h-9 w-9 shrink-0 place-items-center rounded-lg"
            style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-default)' }}
          >
            <X className="h-4 w-4" style={{ color: 'var(--text-secondary)' }} />
          </button>
        </div>

        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto pr-1">
          <Section title="Collecte">
            <Row label="Extraction" value={woolTypeLabels[annex.typeDeLaine] || annex.typeDeLaine} />
            <Row label="Qualite" value={annex.propreteScore ? `${annex.propreteScore}/5` : null} />
            <Row label="Sacs declares" value={annex.sacsCount} />
          </Section>

          <Section title="Tri - Depot D1">
            <Row label="Classification" value={woolClassLabels[annex.classification] || annex.classification} />
            <Row label="Temperature du tas" value={annex.temperatureTasCelsius ? `${annex.temperatureTasCelsius}C` : null} tone={hotPile ? 'alert' : 'neutral'} />
            <Row label="Taux VM" value={annex.tauxMatiereVegetalePercent ? `${annex.tauxMatiereVegetalePercent}%` : null} tone={highVm ? 'warn' : 'neutral'} />
          </Section>

          <Section title="Lavage D2">
            <Row label="Humidite residuelle" value={annex.humiditeSortiePercent ? `${annex.humiditeSortiePercent}%` : null} />
            <Row label="pH laine" value={annex.phLaine} />
            <Row label="Destination" value={batch.finalDestination || 'En cours'} />
          </Section>
        </div>
      </aside>
    </div>
  )
}
