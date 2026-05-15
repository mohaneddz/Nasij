import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { useOutletContext } from 'react-router-dom'
import { useState } from 'react'
import BatchDetailsDrawer from '../components/BatchDetailsDrawer'

function makeDotIcon(color, truck = false) {
  return L.divIcon({
    className: '',
    html: truck
      ? `<div style="
          background: ${color};
          width: 30px; height: 30px;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          box-shadow: 0 0 18px ${color}70, 0 0 0 5px ${color}22;
          font-size: 0;
          color: #061018;
          font-weight: 800;
          border: 2px solid rgba(255,255,255,0.28);
        ">🚚</div>`
      : `<div style="
          background: ${color};
          width: 14px; height: 14px;
          border-radius: 50%;
          box-shadow: 0 0 16px ${color}70, 0 0 0 5px ${color}24;
          border: 2px solid rgba(255,255,255,0.3);
        "></div>`,
    iconSize: truck ? [30, 30] : [14, 14],
    iconAnchor: truck ? [15, 15] : [7, 7],
  })
}

export default function MapPage() {
  const { batches, alerts } = useOutletContext()
  const [selectedBatch, setSelectedBatch] = useState(null)
  const activeAlerts = alerts.filter((alert) => !alert.isResolved)
  const alertBatchIds = new Set(activeAlerts.map((alert) => alert.batchId))
  const alertBatches = batches.filter((batch) => alertBatchIds.has(batch.batchId))

  return (
    <>
      <div
        className="rounded-xl overflow-hidden"
        style={{
          background: 'var(--bg-surface)',
          border: '1px solid var(--border-default)',
          height: 'calc(100vh - 180px)',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {/* Header */}
        <div
          className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 px-5 py-4"
          style={{ borderBottom: '1px solid var(--border-subtle)' }}
        >
          <div className="flex items-center gap-3">
            <div
              className="grid h-8 w-8 place-items-center rounded-lg min-w-[32px]"
              style={{ background: 'var(--accent-blue-muted)', border: '1px solid rgba(138,180,214,0.18)' }}
            >
              <svg className="h-4 w-4" style={{ color: 'var(--accent-blue)' }} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z" />
                <circle cx="12" cy="10" r="3" />
              </svg>
            </div>
            <div>
              <h2
                className="text-sm font-semibold"
                style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
              >
                Cartographie Flotte NFN
              </h2>
              <p className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
                Cliquez un lot pour ouvrir la fiche technique annex.
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center gap-2 rounded-md px-2.5 py-1.5 text-[11px] font-medium" style={{ background: 'var(--accent-emerald-muted)', border: '1px solid rgba(52,211,153,0.18)' }}>
              <span className="h-2 w-2 rounded-full" style={{ background: 'var(--accent-emerald)' }} />
              <span style={{ color: 'var(--text-secondary)' }}>Collecte</span>
            </div>
            <div className="flex items-center gap-2 rounded-md px-2.5 py-1.5 text-[11px] font-medium" style={{ background: 'var(--accent-blue-muted)', border: '1px solid rgba(138,180,214,0.18)' }}>
              <span className="h-2 w-2 rounded-full" style={{ background: 'var(--accent-blue)' }} />
              <span style={{ color: 'var(--text-secondary)' }}>Transit</span>
            </div>
            <div className="flex items-center gap-2 rounded-md px-2.5 py-1.5 text-[11px] font-medium" style={{ background: 'var(--accent-rose-muted)', border: '1px solid rgba(239,68,68,0.22)' }}>
              <span className="h-2 w-2 rounded-full" style={{ background: 'var(--accent-rose)' }} />
              <span style={{ color: 'var(--text-secondary)' }}>Alertes</span>
            </div>
          </div>
        </div>

        {/* Map */}
        <div className="flex-1 min-h-0">
          <MapContainer center={[28.03, 1.66]} zoom={6} style={{ width: '100%', height: '100%' }}>
            <TileLayer url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png" />
            {batches
              .filter((batch) => ['PENDING_PICKUP', 'COLLECTED_BY_BUYER'].includes(batch.status))
              .map((batch) => {
                const icon = batch.status === 'COLLECTED_BY_BUYER'
                  ? makeDotIcon('#60a5fa', true)
                  : makeDotIcon('#22c55e')
                const creatorName = batch.creator?.fullName
                const creatorPhone = batch.creator?.phoneNumber
                const collectorName = batch.collector?.fullName
                const collectorPhone = batch.collector?.phoneNumber

                return (
                  <Marker
                    key={batch.batchId}
                    position={[batch.locationLat, batch.locationLng]}
                    icon={icon}
                    eventHandlers={{ click: () => setSelectedBatch(batch) }}
                  >
                    <Popup>
                      <div style={{ fontFamily: 'var(--font-body)' }}>
                        <div style={{ fontWeight: 700, fontSize: '14px', marginBottom: '8px', color: 'var(--text-primary)' }}>
                          {batch.batchId}
                        </div>
                        <div style={{ height: '1px', background: 'var(--border-default)', marginBottom: '8px' }} />
                        <div style={{ fontSize: '12px', lineHeight: '1.8', color: 'var(--text-secondary)' }}>
                          <div><span style={{ color: 'var(--text-muted)' }}>Zone:</span> {batch.wilaya}</div>
                          <div><span style={{ color: 'var(--text-muted)' }}>Origine:</span> {batch.sourceType}</div>
                          <div><span style={{ color: 'var(--text-muted)' }}>Race:</span> {batch.breed}</div>
                          <div><span style={{ color: 'var(--text-muted)' }}>C1/C2/C3:</span> {creatorName || '—'}{creatorPhone ? ` (${creatorPhone})` : ''}</div>
                          <div><span style={{ color: 'var(--text-muted)' }}>Collecteur:</span> {collectorName || '—'}{collectorPhone ? ` (${collectorPhone})` : ''}</div>
                          <div style={{ marginTop: '4px', fontWeight: 600, color: 'var(--accent-emerald)' }}>
                            {batch.purchasePriceDzd?.toLocaleString()} DZD
                          </div>
                        </div>
                      </div>
                    </Popup>
                  </Marker>
                )
              })}
            {alertBatches.map((batch) => {
              const icon = makeDotIcon('#f43f5e')
              const batchAlerts = activeAlerts.filter((alert) => alert.batchId === batch.batchId)
              const creatorName = batch.creator?.fullName
              const creatorPhone = batch.creator?.phoneNumber
              const collectorName = batch.collector?.fullName
              const collectorPhone = batch.collector?.phoneNumber

              return (
                <Marker
                  key={`alert-${batch.batchId}`}
                  position={[batch.locationLat, batch.locationLng]}
                  icon={icon}
                  eventHandlers={{ click: () => setSelectedBatch(batch) }}
                >
                  <Popup>
                    <div style={{ fontFamily: 'var(--font-body)' }}>
                      <div style={{ fontWeight: 700, fontSize: '14px', marginBottom: '8px', color: 'var(--text-primary)' }}>
                        {batch.batchId}
                      </div>
                      <div style={{ height: '1px', background: 'var(--border-default)', marginBottom: '8px' }} />
                      <div style={{ fontSize: '12px', lineHeight: '1.8', color: 'var(--text-secondary)' }}>
                        <div><span style={{ color: 'var(--text-muted)' }}>Zone:</span> {batch.wilaya}</div>
                        <div><span style={{ color: 'var(--text-muted)' }}>Origine:</span> {batch.sourceType}</div>
                        <div><span style={{ color: 'var(--text-muted)' }}>Alertes:</span> {batchAlerts.length}</div>
                        <div><span style={{ color: 'var(--text-muted)' }}>C1/C2/C3:</span> {creatorName || '—'}{creatorPhone ? ` (${creatorPhone})` : ''}</div>
                        <div><span style={{ color: 'var(--text-muted)' }}>Collecteur:</span> {collectorName || '—'}{collectorPhone ? ` (${collectorPhone})` : ''}</div>
                      </div>
                    </div>
                  </Popup>
                </Marker>
              )
            })}
          </MapContainer>
        </div>
      </div>
      <BatchDetailsDrawer batch={selectedBatch} onClose={() => setSelectedBatch(null)} />
    </>
  )
}
