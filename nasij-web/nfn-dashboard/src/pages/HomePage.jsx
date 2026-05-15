import {
  BellRing,
  Boxes,
  CheckCircle2,
  CircleAlert,
  Droplets,
  Factory,
  MapPin,
  PieChart,
  Route,
  Scissors,
} from 'lucide-react'
import { useOutletContext } from 'react-router-dom'
import { getAnnexKpis, getClassDistributionData, getKpiMetrics } from '../dashboardData'

function toneMap(tone) {
  if (tone === 'alert') return { accent: 'var(--accent-rose)', muted: 'var(--accent-rose-muted)' }
  if (tone === 'warn') return { accent: 'var(--accent-amber)', muted: 'var(--accent-amber-muted)' }
  if (tone === 'success') return { accent: 'var(--accent-emerald)', muted: 'var(--accent-emerald-muted)' }
  return { accent: 'var(--text-secondary)', muted: 'var(--bg-raised)' }
}

function KpiCard({ item }) {
  const Icon = item.icon
  const { accent, muted } = toneMap(item.tone)

  return (
    <section
      className="card-hover rounded-xl p-5"
      style={{
        background: 'var(--bg-surface)',
        border: item.tone === 'alert' ? '1px solid rgba(239,68,68,0.28)' : '1px solid var(--border-default)',
      }}
    >
      <div className="flex items-start justify-between gap-4">
        <p className="text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>
          {item.label}
        </p>
        <div className="grid h-8 w-8 place-items-center rounded-lg" style={{ background: muted, border: `1px solid ${accent}24` }}>
          <Icon className={item.tone === 'alert' ? 'h-4 w-4 animate-pulse' : 'h-4 w-4'} style={{ color: accent }} strokeWidth={2.25} />
        </div>
      </div>

      <div className="mt-3 flex items-baseline gap-1.5">
        <span className="text-[32px] font-semibold leading-none tracking-tight" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
          {item.value}
        </span>
        {item.unit && <span className="text-sm font-medium" style={{ color: 'var(--text-muted)' }}>{item.unit}</span>}
      </div>

      <div className="mt-5">
        <span
          className="inline-flex items-center rounded-md px-2 py-1 text-[11px] font-semibold"
          style={{ background: muted, color: accent, border: `1px solid ${accent}24` }}
        >
          {item.helper}
        </span>
        <p className="mt-2 text-[11px]" style={{ color: 'var(--text-muted)' }}>{item.meta}</p>
      </div>
    </section>
  )
}

function OperationsStrip({ batches }) {
  const pending = batches.filter((b) => ['PENDING_PICKUP', 'AT_D1_STOCKAGE', 'AT_D2_LAVAGE'].includes(b.status)).length
  const transit = batches.filter((b) => b.status === 'COLLECTED_BY_BUYER').length
  const wilayas = new Set(batches.map((b) => b.wilaya)).size
  const total = batches.length || 1
  const conformes = batches.filter((b) => ['READY_FOR_SALE', 'IN_TRANSFORMATION'].includes(b.status)).length
  const conformePercent = Math.round((conformes / total) * 100)

  const operations = [
    { label: 'Lots en attente', value: String(pending), icon: Boxes, color: 'var(--accent-amber)' },
    { label: 'En transit', value: String(transit), icon: Route, color: 'var(--accent-blue)' },
    { label: 'Wilayas actives', value: String(wilayas), icon: MapPin, color: 'var(--text-secondary)' },
    { label: 'Lots conformes', value: `${conformePercent}%`, icon: CheckCircle2, color: 'var(--accent-emerald)' },
  ]

  return (
    <section className="grid grid-cols-2 overflow-hidden rounded-xl xl:grid-cols-4" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
      {operations.map((item, index) => {
        const Icon = item.icon
        return (
          <div key={item.label} className="p-4" style={index > 0 ? { borderLeft: '1px solid var(--border-subtle)' } : {}}>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>{item.label}</p>
                <p className="mt-2 text-xl font-semibold tabular-nums" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>{item.value}</p>
              </div>
              <Icon className="h-5 w-5" style={{ color: item.color }} strokeWidth={2} />
            </div>
          </div>
        )
      })}
    </section>
  )
}

function D1QualityDonut({ classA, classB }) {
  return (
    <section className="rounded-xl p-6" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Qualite du tri (D1)</p>
          <h2 className="mt-1 text-base font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>Classe A vs Classe B</h2>
        </div>
        <PieChart className="h-5 w-5" style={{ color: 'var(--accent-emerald)' }} />
      </div>

      <div className="mt-6 flex items-center gap-6">
        <div
          className="grid h-32 w-32 shrink-0 place-items-center rounded-full"
          style={{ background: `conic-gradient(var(--accent-emerald) 0 ${classA}%, var(--accent-amber) ${classA}% 100%)` }}
        >
          <div className="grid h-20 w-20 place-items-center rounded-full" style={{ background: 'var(--bg-surface)' }}>
            <span className="text-xl font-semibold tabular-nums" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>{classA}%</span>
          </div>
        </div>

        <div className="min-w-0 flex-1 space-y-3">
          <div>
            <div className="flex items-center justify-between text-sm">
              <span style={{ color: 'var(--accent-emerald)' }}>Classe A - Propre</span>
              <span className="font-semibold tabular-nums" style={{ color: 'var(--text-primary)' }}>{classA}%</span>
            </div>
            <div className="mt-2 h-1.5 overflow-hidden rounded-full" style={{ background: 'var(--border-subtle)' }}>
              <div className="h-full rounded-full" style={{ width: `${classA}%`, background: 'var(--accent-emerald)' }} />
            </div>
          </div>
          <div>
            <div className="flex items-center justify-between text-sm">
              <span style={{ color: 'var(--accent-amber)' }}>Classe B - Souillee</span>
              <span className="font-semibold tabular-nums" style={{ color: 'var(--text-primary)' }}>{classB}%</span>
            </div>
            <div className="mt-2 h-1.5 overflow-hidden rounded-full" style={{ background: 'var(--border-subtle)' }}>
              <div className="h-full rounded-full" style={{ width: `${classB}%`, background: 'var(--accent-amber)' }} />
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default function HomePage() {
  const { batches, alerts } = useOutletContext()
  const kpiData = getKpiMetrics(batches, alerts)
  const annex = getAnnexKpis(batches)
  const classSplit = getClassDistributionData(batches)
  const recentAnomalies = alerts.filter((a) => !a.isResolved).slice(0, 3)
  const d3Count = batches.filter((b) => b.finalDestination === 'D3').length
  const d4Count = batches.filter((b) => b.finalDestination === 'D4').length
  const qualityTotal = d3Count + d4Count || 1

  const kpis = [
    {
      label: 'Rendement Tonte (C1)',
      value: annex.tonteYield,
      unit: '%',
      helper: `Cible: ${annex.tonteTarget}`,
      meta: 'Annex 2 - source C1',
      icon: Scissors,
      tone: 'success',
    },
    {
      label: 'Rendement Abattage (C2)',
      value: annex.abattageYield,
      unit: '%',
      helper: `Cible: ${annex.abattageTarget}`,
      meta: 'Annex 2 - source C2',
      icon: Factory,
      tone: 'warn',
    },
    {
      label: 'Rendement Moyen (D2)',
      value: kpiData.averageYield,
      unit: '%',
      helper: 'Lavage controle',
      meta: 'Sortie D2 / entree D1',
      icon: Droplets,
      tone: Number(kpiData.averageYield) >= 40 ? 'success' : 'warn',
    },
    {
      label: 'Alertes Actives',
      value: String(kpiData.activeAlerts),
      unit: '',
      helper: kpiData.activeAlerts > 0 ? 'Traitement requis' : 'Tout operationnel',
      meta: 'Annex thresholds',
      icon: BellRing,
      tone: kpiData.activeAlerts > 0 ? 'alert' : 'success',
    },
  ]

  return (
    <div className="space-y-5">
      <OperationsStrip batches={batches} />

      <section className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        {kpis.map((item) => <KpiCard key={item.label} item={item} />)}
      </section>

      <section className="grid grid-cols-1 gap-4 xl:grid-cols-[minmax(0,1fr)_minmax(0,0.8fr)_minmax(300px,0.75fr)]">
        <D1QualityDonut classA={classSplit.classA} classB={classSplit.classB} />

        <section className="rounded-xl p-6" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
          <p className="text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Routage final</p>
          <h2 className="mt-1 text-base font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>D3 / D4</h2>

          <div className="mt-6 space-y-5">
            <div>
              <div className="flex items-center justify-between text-sm">
                <span style={{ color: 'var(--accent-emerald)' }}>D3 - Isolants</span>
                <span className="font-semibold tabular-nums" style={{ color: 'var(--text-primary)' }}>{d3Count} lots</span>
              </div>
              <div className="mt-2 h-3 overflow-hidden rounded-full" style={{ background: 'var(--border-subtle)' }}>
                <div className="h-full rounded-full" style={{ width: `${(d3Count / qualityTotal) * 100}%`, background: 'var(--accent-emerald)' }} />
              </div>
            </div>
            <div>
              <div className="flex items-center justify-between text-sm">
                <span style={{ color: 'var(--accent-amber)' }}>D4 - Engrais</span>
                <span className="font-semibold tabular-nums" style={{ color: 'var(--text-primary)' }}>{d4Count} lots</span>
              </div>
              <div className="mt-2 h-3 overflow-hidden rounded-full" style={{ background: 'var(--border-subtle)' }}>
                <div className="h-full rounded-full" style={{ width: `${(d4Count / qualityTotal) * 100}%`, background: 'var(--accent-amber)' }} />
              </div>
            </div>
          </div>
        </section>

        <section className="rounded-xl" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
          <div className="flex items-start justify-between gap-4 px-6 py-5" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--accent-rose)' }}>Annex alerts</p>
              <h2 className="mt-1 text-base font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>Dernieres anomalies</h2>
            </div>
            <CircleAlert className="h-5 w-5 pulse-rose" style={{ color: 'var(--accent-rose)' }} strokeWidth={2.25} />
          </div>

          <div className="space-y-3 p-4">
            {recentAnomalies.map((alert) => (
              <article key={alert.id} className="rounded-lg p-4" style={{ background: 'var(--bg-raised)', border: '1px solid rgba(239,68,68,0.22)' }}>
                <span className="rounded px-2 py-1 text-[10px] font-bold uppercase tracking-wider" style={{ background: 'var(--accent-rose-muted)', color: 'var(--accent-rose)', border: '1px solid rgba(239,68,68,0.2)' }}>
                  {alert.alertType?.replace(/_/g, ' ') || 'Alerte'}
                </span>
                <p className="mt-3 text-sm font-medium leading-relaxed" style={{ color: 'var(--text-primary)' }}>{alert.description}</p>
              </article>
            ))}
          </div>
        </section>
      </section>
    </div>
  )
}
