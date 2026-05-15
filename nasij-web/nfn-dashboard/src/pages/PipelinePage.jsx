import { useState } from 'react'
import { getBatchAnnexDetails, pipelineColumns, woolClassLabels } from '../dashboardData'
import { useOutletContext } from 'react-router-dom'
import {
  Cpu,
  Droplets,
  GitBranch,
  Warehouse,
} from 'lucide-react'
import BatchDetailsDrawer from '../components/BatchDetailsDrawer'

const phaseIcons = {
  COLLECTE: GitBranch,
  D1: Warehouse,
  D2: Droplets,
  TRANSFORMATION: Cpu,
}

const phaseColors = {
  COLLECTE: 'var(--accent-emerald)',
  D1: 'var(--accent-amber)',
  D2: 'var(--accent-blue)',
  TRANSFORMATION: 'var(--accent-purple)',
}

function Row({ label, value, valueColor }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="text-[11px] font-medium" style={{ color: 'var(--text-muted)' }}>{label}</span>
      <span className="text-[11px] font-semibold tabular-nums text-right" style={{ color: valueColor || 'var(--text-primary)' }}>
        {value ?? '-'}
      </span>
    </div>
  )
}

function ClassificationTag({ value }) {
  if (!value) return null

  const isA = value === 'CLASSE_A_PROPRE'
  return (
    <span
      className="rounded px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider"
      style={{
        background: isA ? 'var(--accent-emerald-muted)' : 'var(--accent-amber-muted)',
        color: isA ? 'var(--accent-emerald)' : 'var(--accent-amber)',
        border: `1px solid ${isA ? 'rgba(52,211,153,0.2)' : 'rgba(240,180,91,0.22)'}`,
      }}
    >
      {isA ? 'Classe A' : 'Classe B'}
    </span>
  )
}

function BatchCard({ batch, columnKey, color, onSelect }) {
  const annex = getBatchAnnexDetails(batch)

  return (
    <button
      type="button"
      onClick={() => onSelect(batch)}
      className="card-hover w-full rounded-lg p-4 text-left"
      style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-subtle)' }}
    >
      <div className="mb-3 flex items-center justify-between gap-3">
        <span className="text-sm font-bold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
          {batch.batchId}
        </span>
        <div className="flex items-center gap-1.5">
          {columnKey === 'D1' && <ClassificationTag value={annex.classification} />}
          <span className="rounded px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wider" style={{ background: `${color}14`, color, border: `1px solid ${color}22` }}>
            {batch.status.replace(/_/g, ' ')}
          </span>
        </div>
      </div>

      <div className="mb-3">
        <p className="text-[12px] font-medium" style={{ color: 'var(--text-secondary)' }}>
          {batch.sourceType} / {batch.wilaya}
        </p>
        <p className="mt-0.5 text-[12px] font-semibold" style={{ color: 'var(--text-primary)' }}>
          Race: {batch.breed}
        </p>
      </div>

      <div className="rounded-md p-3 space-y-2" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-subtle)' }}>
        {columnKey === 'COLLECTE' && (
          <>
            <Row label="Type laine" value={annex.typeDeLaine?.replace(/_/g, ' ')} />
            <Row label="Qualite" value={annex.propreteScore ? `${annex.propreteScore}/5` : '-'} valueColor="var(--accent-emerald)" />
          </>
        )}
        {columnKey === 'D1' && (
          <>
            <Row label="Classification" value={woolClassLabels[annex.classification] || annex.classification} valueColor={annex.classification === 'CLASSE_A_PROPRE' ? 'var(--accent-emerald)' : 'var(--accent-amber)'} />
            <Row label="Temperature" value={annex.temperatureTasCelsius ? `${annex.temperatureTasCelsius}C` : '-'} valueColor={annex.temperatureTasCelsius >= 42 ? 'var(--accent-rose)' : undefined} />
            <Row label="VM" value={annex.tauxMatiereVegetalePercent ? `${annex.tauxMatiereVegetalePercent}%` : '-'} valueColor={annex.tauxMatiereVegetalePercent > 5 ? 'var(--accent-amber)' : undefined} />
          </>
        )}
        {columnKey === 'D2' && (
          <>
            <Row label="Propre D2" value={batch.weightCleanD2Kg ? `${batch.weightCleanD2Kg} kg` : '-'} />
            <Row label="Humidite sortie" value={annex.humiditeSortiePercent ? `${annex.humiditeSortiePercent}%` : '-'} />
            <Row label="pH" value={annex.phLaine || '-'} />
          </>
        )}
        {columnKey === 'TRANSFORMATION' && (
          <>
            <Row label="Calibre" value={batch.fiberLengthMm ? `${batch.fiberLengthMm}mm / ${batch.finesseMicron}um` : 'Controle en cours'} />
            <Row label="Destination" value={batch.finalDestination || 'En cours'} valueColor={batch.finalDestination === 'D3' ? 'var(--accent-emerald)' : 'var(--accent-amber)'} />
          </>
        )}
      </div>
    </button>
  )
}

function TransformationGroups({ rows, color, onSelect }) {
  const d3Rows = rows.filter((batch) => batch.finalDestination === 'D3')
  const d4Rows = rows.filter((batch) => batch.finalDestination === 'D4')
  const inProgress = rows.filter((batch) => !['D3', 'D4'].includes(batch.finalDestination))

  const groups = [
    { title: 'D3: Isolants', rows: d3Rows, color: 'var(--accent-emerald)' },
    { title: 'D4: Engrais', rows: d4Rows, color: 'var(--accent-amber)' },
    { title: 'Controle final', rows: inProgress, color },
  ].filter((group) => group.rows.length)

  return (
    <div className="flex-1 overflow-y-auto space-y-4 p-3">
      {groups.map((group) => (
        <section key={group.title} className="rounded-lg p-2" style={{ background: 'var(--bg-surface)', border: `1px solid ${group.color}24` }}>
          <div className="mb-2 flex items-center justify-between px-1">
            <span className="text-[10px] font-bold uppercase tracking-[0.1em]" style={{ color: group.color }}>{group.title}</span>
            <span className="text-[10px] font-semibold tabular-nums" style={{ color: 'var(--text-muted)' }}>{group.rows.length}</span>
          </div>
          <div className="space-y-3">
            {group.rows.map((batch) => <BatchCard key={batch.batchId} batch={batch} columnKey="TRANSFORMATION" color={group.color} onSelect={onSelect} />)}
          </div>
        </section>
      ))}
    </div>
  )
}

export default function PipelinePage() {
  const { batches } = useOutletContext()
  const [selectedBatch, setSelectedBatch] = useState(null)

  return (
    <>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        {pipelineColumns.map((column) => {
          const rows = batches.filter((batch) => column.statuses.includes(batch.status))
          const Icon = phaseIcons[column.key] || GitBranch
          const color = phaseColors[column.key] || 'var(--text-secondary)'

          return (
            <div
              key={column.key}
              className="flex flex-col rounded-xl"
              style={{
                background: 'var(--bg-surface)',
                border: '1px solid var(--border-default)',
                maxHeight: 'calc(100vh - 180px)',
              }}
            >
              <div className="px-4 py-4" style={{ borderBottom: `2px solid ${color}` }}>
                <div className="flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5">
                    <div className="grid h-7 w-7 place-items-center rounded-md" style={{ background: `${color}18`, border: `1px solid ${color}24` }}>
                      <Icon className="h-3.5 w-3.5" style={{ color }} strokeWidth={2.25} />
                    </div>
                    <span className="text-[13px] font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
                      {column.title}
                    </span>
                  </div>
                  <span className="grid h-6 min-w-[24px] place-items-center rounded-md px-1.5 text-[11px] font-bold tabular-nums" style={{ background: 'var(--bg-raised)', color: 'var(--text-secondary)', border: '1px solid var(--border-subtle)' }}>
                    {rows.length}
                  </span>
                </div>
              </div>

              {column.key === 'TRANSFORMATION' ? (
                <TransformationGroups rows={rows} color={color} onSelect={setSelectedBatch} />
              ) : (
                <div className="flex-1 overflow-y-auto space-y-3 p-3">
                  {rows.map((batch) => <BatchCard key={batch.batchId} batch={batch} columnKey={column.key} color={color} onSelect={setSelectedBatch} />)}
                  {!rows.length && (
                    <div className="flex items-center justify-center rounded-lg p-8" style={{ border: '1px dashed var(--border-default)' }}>
                      <span className="text-[12px] font-medium" style={{ color: 'var(--text-muted)' }}>Aucune donnee</span>
                    </div>
                  )}
                </div>
              )}
            </div>
          )
        })}
      </div>
      <BatchDetailsDrawer batch={selectedBatch} onClose={() => setSelectedBatch(null)} />
    </>
  )
}
