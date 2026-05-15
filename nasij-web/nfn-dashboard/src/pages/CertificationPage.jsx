import { useState } from 'react'
import { QRCodeSVG } from 'qrcode.react'
import { useOutletContext } from 'react-router-dom'
import { Award, ShieldCheck, X } from 'lucide-react'

export default function CertificationPage() {
  const [selectedBatch, setSelectedBatch] = useState(null)
  const { batches } = useOutletContext()
  const readyForSale = batches.filter((batch) => batch.status === 'READY_FOR_SALE')

  return (
    <>
      <div
        className="rounded-xl"
        style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}
      >
        {/* Header */}
        <div className="flex items-center gap-3 px-6 py-5" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
          <div
            className="grid h-9 w-9 place-items-center rounded-lg"
            style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-default)' }}
          >
            <Award className="h-4 w-4" style={{ color: 'var(--text-secondary)' }} strokeWidth={2.25} />
          </div>
          <div>
            <h2
              className="text-base font-semibold"
              style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
            >
              Lots Certifies Sceau NFN
            </h2>
            <p className="text-[11px]" style={{ color: 'var(--text-muted)' }}>
              Generation de passeports digitaux pour exportation.
            </p>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr style={{ borderBottom: '1px solid var(--border-default)' }}>
                <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Lot</th>
                <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Race</th>
                <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Longueur</th>
                <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Finesse</th>
                <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Humidite</th>
                <th className="px-6 py-3.5 text-center text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Sceau</th>
              </tr>
            </thead>
            <tbody>
              {readyForSale.length > 0 ? readyForSale.map((batch, index) => (
                <tr
                  key={batch.batchId}
                  className="transition-colors duration-150"
                  style={{
                    borderBottom: index < readyForSale.length - 1 ? '1px solid var(--border-subtle)' : 'none',
                    background: index % 2 === 1 ? 'var(--bg-raised)' : 'transparent',
                  }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(148,163,184,0.04)' }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = index % 2 === 1 ? 'var(--bg-raised)' : 'transparent' }}
                >
                  <td className="px-6 py-4">
                    <span className="text-[13px] font-bold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
                      {batch.batchId}
                    </span>
                    <br />
                    <span className="text-[11px]" style={{ color: 'var(--text-muted)' }}>{batch.wilaya}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span
                      className="rounded-md px-2 py-1 text-[11px] font-bold"
                      style={{ background: 'var(--bg-raised)', color: 'var(--text-secondary)', border: '1px solid var(--border-default)' }}
                    >
                      {batch.breed}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-[13px] font-semibold tabular-nums" style={{ color: 'var(--text-primary)' }}>{batch.fiberLengthMm} mm</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-[13px] font-semibold tabular-nums" style={{ color: 'var(--text-primary)' }}>{batch.finesseMicron} um</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-[13px] font-semibold tabular-nums" style={{ color: 'var(--text-primary)' }}>{batch.humidityPercent}%</span>
                  </td>
                  <td className="px-6 py-4 text-center">
                    <button
                      type="button"
                      onClick={() => setSelectedBatch(batch)}
                      className="inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-[12px] font-semibold transition-all duration-200"
                      style={{
                        background: 'var(--bg-raised)',
                        color: 'var(--text-secondary)',
                        border: '1px solid var(--border-default)',
                      }}
                    >
                      <ShieldCheck className="h-3.5 w-3.5" strokeWidth={2.25} />
                      Generer
                    </button>
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center">
                    <p className="text-sm font-medium" style={{ color: 'var(--text-muted)' }}>
                      Aucun lot certifie en attente.
                    </p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Certificate Modal */}
      {selectedBatch && (
        <div className="modal-backdrop" onClick={() => setSelectedBatch(null)}>
          <div className="modal-panel" onClick={(e) => e.stopPropagation()}>
            <div className="p-6">
              {/* Modal header */}
              <div className="flex items-center justify-between gap-4 mb-5">
                <div className="flex items-center gap-2">
                  <Award className="h-5 w-5" style={{ color: 'var(--text-secondary)' }} strokeWidth={2.25} />
                  <span
                    className="text-lg font-bold"
                    style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
                  >
                    Passeport NFN
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedBatch(null)}
                  className="grid h-7 w-7 place-items-center rounded-md transition-colors hover:bg-white/5"
                >
                  <X className="h-4 w-4" style={{ color: 'var(--text-muted)' }} />
                </button>
              </div>

              {/* Batch ID */}
              <div className="text-center mb-5">
                <span
                  className="text-xl font-bold"
                  style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
                >
                  {selectedBatch.batchId}
                </span>
                <p className="mt-1 text-[12px] font-semibold" style={{ color: 'var(--text-secondary)' }}>
                  {selectedBatch.finalDestination === 'D3' ? 'Habillement / Textiles' : 'Bio-fertilisants'}
                </p>
              </div>

              {/* Details grid */}
              <div
                className="rounded-lg p-4 mb-5 grid grid-cols-2 gap-4"
                style={{ background: 'var(--bg-surface)', border: '1px dashed var(--border-default)' }}
              >
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider" style={{ color: 'var(--text-muted)' }}>
                    Origine
                  </p>
                  <p className="mt-0.5 text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                    {selectedBatch.wilaya}
                  </p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider" style={{ color: 'var(--text-muted)' }}>
                    Genetique
                  </p>
                  <p className="mt-0.5 text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                    {selectedBatch.breed}
                  </p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider" style={{ color: 'var(--text-muted)' }}>
                    Qualite Fibre
                  </p>
                  <p className="mt-0.5 text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                    {selectedBatch.fiberLengthMm}mm / {selectedBatch.finesseMicron}um
                  </p>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider" style={{ color: 'var(--text-muted)' }}>
                    Certifie par
                  </p>
                  <p className="mt-0.5 text-[13px] font-semibold" style={{ color: 'var(--text-secondary)' }}>
                    Etat Algerien
                  </p>
                </div>
              </div>

              {/* QR Code */}
              <div className="flex justify-center mb-4">
                <div
                  className="rounded-xl p-4"
                  style={{ background: '#ffffff', boxShadow: '0 12px 30px rgba(0,0,0,0.18)' }}
                >
                  <QRCodeSVG
                    value={JSON.stringify({
                      batchId: selectedBatch.batchId,
                      wilaya: selectedBatch.wilaya,
                      breed: selectedBatch.breed,
                      fiber: `${selectedBatch.fiberLengthMm}mm / ${selectedBatch.finesseMicron}um`,
                      destination: selectedBatch.finalDestination,
                      certifiedBy: 'Algerian Ministry',
                    })}
                    size={160}
                    bgColor="#ffffff"
                    fgColor="#0f1520"
                    level="H"
                  />
                </div>
              </div>

              <p className="text-center text-[11px] font-medium mb-5" style={{ color: 'var(--text-muted)' }}>
                Scannez pour verifier l'authenticite sur le reseau NFN.
              </p>

              <button
                type="button"
                onClick={() => setSelectedBatch(null)}
                className="w-full rounded-lg py-2.5 text-[13px] font-semibold transition-colors duration-200"
                style={{
                  background: 'var(--bg-surface)',
                  color: 'var(--text-secondary)',
                  border: '1px solid var(--border-default)',
                }}
              >
                Fermer
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
