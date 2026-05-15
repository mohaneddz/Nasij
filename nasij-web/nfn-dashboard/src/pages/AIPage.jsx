import React, { useState, useCallback } from 'react';
import { Brain, TrendingUp, Camera, Upload, Loader2, CheckCircle, AlertTriangle, Sparkles } from 'lucide-react';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const CONDITION_STYLES = {
  NEW: { bg: 'var(--accent-emerald-muted)', color: 'var(--accent-emerald)', label: 'Excellent' },
  SLIGHTLY: { bg: 'var(--accent-blue-muted)', color: 'var(--accent-blue)', label: 'Bon' },
  MODERATE: { bg: 'var(--accent-amber-muted)', color: 'var(--accent-amber)', label: 'Moyen' },
  BAD: { bg: 'var(--accent-rose-muted)', color: 'var(--accent-rose)', label: 'Mauvais' },
};

const AIPage = () => {
  const [activeTab, setActiveTab] = useState('forecast');

  // Forecast state
  const [horizon, setHorizon] = useState(3);
  const [lookback, setLookback] = useState(15);
  const [forecastResult, setForecastResult] = useState(null);
  const [forecastLoading, setForecastLoading] = useState(false);
  const [forecastError, setForecastError] = useState('');

  // Photo state
  const [selectedFile, setSelectedFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [photoResult, setPhotoResult] = useState(null);
  const [photoLoading, setPhotoLoading] = useState(false);
  const [photoError, setPhotoError] = useState('');
  const [isDragOver, setIsDragOver] = useState(false);

  const handleForecast = async () => {
    setForecastLoading(true);
    setForecastError('');
    setForecastResult(null);
    try {
      const res = await fetch(`${API_URL}/api/ai/forecast`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ horizon_years: horizon, lookback_years: lookback }),
      });
      if (!res.ok) throw new Error((await res.json()).detail || 'Forecast failed');
      setForecastResult(await res.json());
    } catch (e) {
      setForecastError(e.message);
    } finally {
      setForecastLoading(false);
    }
  };

  const handleFilePick = (file) => {
    if (!file) return;
    setSelectedFile(file);
    setPreviewUrl(URL.createObjectURL(file));
    setPhotoResult(null);
    setPhotoError('');
  };

  const handleDrop = useCallback((e) => {
    e.preventDefault();
    setIsDragOver(false);
    const file = e.dataTransfer.files?.[0];
    if (file && file.type.startsWith('image/')) handleFilePick(file);
  }, []);

  const handleVerify = async () => {
    if (!selectedFile) return;
    setPhotoLoading(true);
    setPhotoError('');
    setPhotoResult(null);
    try {
      const formData = new FormData();
      formData.append('file', selectedFile);
      const res = await fetch(`${API_URL}/api/ai/verify-photo`, {
        method: 'POST',
        body: formData,
      });
      if (!res.ok) throw new Error((await res.json()).detail || 'Verification failed');
      setPhotoResult(await res.json());
    } catch (e) {
      setPhotoError(e.message);
    } finally {
      setPhotoLoading(false);
    }
  };

  const inputStyle = {
    background: 'var(--bg-base)',
    border: '1px solid var(--border-strong)',
    color: 'var(--text-primary)',
  };

  return (
    <div className="space-y-6">
      {/* Tab Navigation */}
      <div style={{ borderBottom: '1px solid var(--border-default)' }}>
        <nav className="-mb-px flex space-x-8" aria-label="AI Tabs">
          <button
            onClick={() => setActiveTab('forecast')}
            className="flex items-center whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors"
            style={{
              borderColor: activeTab === 'forecast' ? 'var(--text-primary)' : 'transparent',
              color: activeTab === 'forecast' ? 'var(--text-primary)' : 'var(--text-muted)',
            }}
          >
            <TrendingUp className="mr-2 h-4 w-4" />
            Prevision de Demande
          </button>
          <button
            onClick={() => setActiveTab('photo')}
            className="flex items-center whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition-colors"
            style={{
              borderColor: activeTab === 'photo' ? 'var(--text-primary)' : 'transparent',
              color: activeTab === 'photo' ? 'var(--text-primary)' : 'var(--text-muted)',
            }}
          >
            <Camera className="mr-2 h-4 w-4" />
            Verification Photo
          </button>
        </nav>
      </div>

      {/* ─── FORECAST TAB ─── */}
      {activeTab === 'forecast' && (
        <div className="space-y-6">
          {/* Controls */}
          <div
            className="rounded-xl p-6 max-w-2xl"
            style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}
          >
            <h2
              className="text-base font-semibold mb-6 flex items-center"
              style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
            >
              <Sparkles className="mr-2 h-5 w-5" style={{ color: 'var(--accent-emerald)' }} />
              Prevision de la Demande en Laine
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-6">
              <div>
                <label className="block text-xs font-semibold uppercase tracking-[0.1em] mb-1.5" style={{ color: 'var(--text-muted)' }}>
                  Horizon (annees): {horizon}
                </label>
                <input
                  type="range"
                  min={1}
                  max={10}
                  value={horizon}
                  onChange={(e) => setHorizon(Number(e.target.value))}
                  className="w-full accent-[var(--accent-emerald)]"
                />
                <div className="flex justify-between text-[10px] mt-1" style={{ color: 'var(--text-muted)' }}>
                  <span>1 an</span><span>10 ans</span>
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold uppercase tracking-[0.1em] mb-1.5" style={{ color: 'var(--text-muted)' }}>
                  Historique (annees): {lookback}
                </label>
                <input
                  type="range"
                  min={5}
                  max={60}
                  value={lookback}
                  onChange={(e) => setLookback(Number(e.target.value))}
                  className="w-full accent-[var(--accent-emerald)]"
                />
                <div className="flex justify-between text-[10px] mt-1" style={{ color: 'var(--text-muted)' }}>
                  <span>5 ans</span><span>60 ans</span>
                </div>
              </div>
            </div>

            <button
              onClick={handleForecast}
              disabled={forecastLoading}
              className="inline-flex items-center py-2 px-6 rounded-md text-[13px] font-semibold transition-colors duration-200 disabled:opacity-50"
              style={{ background: 'var(--text-primary)', color: 'var(--bg-base)' }}
            >
              {forecastLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <TrendingUp className="mr-2 h-4 w-4" />}
              {forecastLoading ? 'Calcul en cours...' : 'Lancer la Prevision'}
            </button>

            {forecastError && (
              <div className="mt-4 p-3 rounded-md text-sm" style={{ background: 'var(--accent-rose-muted)', color: 'var(--accent-rose)' }}>
                {forecastError}
              </div>
            )}
          </div>

          {/* Results */}
          {forecastResult && (
            <div className="rounded-xl overflow-hidden max-w-3xl" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
              <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
                    Resultats de la Prevision
                  </h3>
                  <span
                    className="rounded-md px-2.5 py-1 text-[11px] font-bold"
                    style={{
                      background: forecastResult.confidence >= 0.7 ? 'var(--accent-emerald-muted)' : 'var(--accent-amber-muted)',
                      color: forecastResult.confidence >= 0.7 ? 'var(--accent-emerald)' : 'var(--accent-amber)',
                      border: `1px solid ${forecastResult.confidence >= 0.7 ? 'rgba(143,189,164,0.2)' : 'rgba(199,173,118,0.2)'}`,
                    }}
                  >
                    Confiance: {(forecastResult.confidence * 100).toFixed(1)}%
                  </span>
                </div>
                <p className="mt-1 text-[11px]" style={{ color: 'var(--text-muted)' }}>
                  Derniere annee historique: {forecastResult.last_historical_year} | Type: {forecastResult.forecast_type}
                </p>
              </div>

              {/* Table */}
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr style={{ borderBottom: '1px solid var(--border-default)' }}>
                      <th className="px-6 py-3.5 text-left text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Annee</th>
                      <th className="px-6 py-3.5 text-right text-[10px] font-semibold uppercase tracking-[0.1em]" style={{ color: 'var(--text-muted)' }}>Demande (kg)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {forecastResult.forecast.map((row, idx) => (
                      <tr
                        key={row.year}
                        style={{
                          borderBottom: idx < forecastResult.forecast.length - 1 ? '1px solid var(--border-subtle)' : 'none',
                          background: idx % 2 === 1 ? 'var(--bg-raised)' : 'transparent',
                        }}
                      >
                        <td className="px-6 py-3.5 text-[13px] font-semibold" style={{ color: 'var(--text-primary)' }}>{row.year}</td>
                        <td className="px-6 py-3.5 text-right text-[13px] font-medium" style={{ color: 'var(--accent-emerald)', fontFeatureSettings: '"tnum"' }}>
                          {row.demand_kg.toLocaleString('fr-FR', { maximumFractionDigits: 0 })} kg
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Drivers */}
              <div className="px-6 py-4" style={{ borderTop: '1px solid var(--border-subtle)' }}>
                <p className="text-[10px] font-semibold uppercase tracking-[0.1em] mb-2" style={{ color: 'var(--text-muted)' }}>Facteurs du modele</p>
                <div className="flex flex-wrap gap-2">
                  {forecastResult.drivers.map((d, i) => (
                    <span
                      key={i}
                      className="rounded-md px-2 py-1 text-[11px] font-medium"
                      style={{ background: 'var(--bg-raised)', color: 'var(--text-secondary)', border: '1px solid var(--border-strong)' }}
                    >
                      {d}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ─── PHOTO TAB ─── */}
      {activeTab === 'photo' && (
        <div className="space-y-6 max-w-2xl">
          {/* Upload Zone */}
          <div
            className="rounded-xl p-6"
            style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}
          >
            <h2
              className="text-base font-semibold mb-6 flex items-center"
              style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}
            >
              <Camera className="mr-2 h-5 w-5" style={{ color: 'var(--accent-blue)' }} />
              Controle Qualite Laine par IA
            </h2>

            {/* Drag & Drop Zone */}
            <div
              onDragOver={(e) => { e.preventDefault(); setIsDragOver(true); }}
              onDragLeave={() => setIsDragOver(false)}
              onDrop={handleDrop}
              onClick={() => document.getElementById('photo-upload').click()}
              className="rounded-lg p-8 text-center cursor-pointer transition-all duration-200"
              style={{
                border: `2px dashed ${isDragOver ? 'var(--accent-blue)' : 'var(--border-strong)'}`,
                background: isDragOver ? 'var(--accent-blue-muted)' : 'var(--bg-base)',
              }}
            >
              <input
                id="photo-upload"
                type="file"
                accept="image/*"
                className="hidden"
                onChange={(e) => handleFilePick(e.target.files?.[0])}
              />
              {previewUrl ? (
                <div className="space-y-3">
                  <img src={previewUrl} alt="Preview" className="mx-auto max-h-48 rounded-lg object-contain" />
                  <p className="text-[12px] font-medium" style={{ color: 'var(--text-secondary)' }}>
                    {selectedFile?.name} — Cliquez pour changer
                  </p>
                </div>
              ) : (
                <>
                  <Upload className="mx-auto h-10 w-10 mb-3" style={{ color: 'var(--text-muted)' }} strokeWidth={1.5} />
                  <p className="text-[13px] font-medium" style={{ color: 'var(--text-secondary)' }}>
                    Glissez une photo de laine ici
                  </p>
                  <p className="text-[11px] mt-1" style={{ color: 'var(--text-muted)' }}>
                    ou cliquez pour selectionner un fichier
                  </p>
                </>
              )}
            </div>

            <button
              onClick={handleVerify}
              disabled={!selectedFile || photoLoading}
              className="mt-5 inline-flex items-center py-2 px-6 rounded-md text-[13px] font-semibold transition-colors duration-200 disabled:opacity-50"
              style={{ background: 'var(--text-primary)', color: 'var(--bg-base)' }}
            >
              {photoLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Brain className="mr-2 h-4 w-4" />}
              {photoLoading ? 'Analyse en cours...' : 'Analyser la Photo'}
            </button>

            {photoError && (
              <div className="mt-4 p-3 rounded-md text-sm" style={{ background: 'var(--accent-rose-muted)', color: 'var(--accent-rose)' }}>
                {photoError}
              </div>
            )}
          </div>

          {/* Results */}
          {photoResult && (
            <div className="rounded-xl overflow-hidden" style={{ background: 'var(--bg-surface)', border: '1px solid var(--border-default)' }}>
              <div className="px-6 py-5" style={{ borderBottom: '1px solid var(--border-subtle)' }}>
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-semibold" style={{ fontFamily: 'var(--font-display)', color: 'var(--text-primary)' }}>
                    Resultat de l'Analyse
                  </h3>
                  {photoResult.needs_human_review && (
                    <span
                      className="rounded-md px-2.5 py-1 text-[11px] font-bold flex items-center gap-1"
                      style={{ background: 'var(--accent-amber-muted)', color: 'var(--accent-amber)' }}
                    >
                      <AlertTriangle className="h-3 w-3" />
                      Revision manuelle requise
                    </span>
                  )}
                </div>
              </div>

              <div className="px-6 py-5 space-y-4">
                {/* Main verdict */}
                <div className="flex items-center gap-4">
                  <div
                    className="grid h-14 w-14 place-items-center rounded-lg"
                    style={{
                      background: photoResult.is_wool ? 'var(--accent-emerald-muted)' : 'var(--accent-rose-muted)',
                      border: `1px solid ${photoResult.is_wool ? 'rgba(143,189,164,0.2)' : 'rgba(239,68,68,0.2)'}`,
                    }}
                  >
                    {photoResult.is_wool
                      ? <CheckCircle className="h-6 w-6" style={{ color: 'var(--accent-emerald)' }} />
                      : <AlertTriangle className="h-6 w-6" style={{ color: 'var(--accent-rose)' }} />
                    }
                  </div>
                  <div>
                    <p className="text-[15px] font-semibold" style={{ color: 'var(--text-primary)' }}>
                      {photoResult.is_wool ? 'Laine detectee' : 'Pas de laine detectee'}
                    </p>
                    <p className="text-[12px] mt-0.5" style={{ color: 'var(--text-muted)' }}>
                      Type: {photoResult.photo_type.replace(/_/g, ' ')}
                    </p>
                  </div>
                </div>

                {/* Metrics grid */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  {[
                    {
                      label: 'Condition',
                      value: (CONDITION_STYLES[photoResult.wool_condition] || CONDITION_STYLES.BAD).label,
                      style: CONDITION_STYLES[photoResult.wool_condition] || CONDITION_STYLES.BAD,
                    },
                    {
                      label: 'Confiance',
                      value: `${(photoResult.confidence * 100).toFixed(1)}%`,
                      style: {
                        bg: photoResult.confidence >= 0.7 ? 'var(--accent-emerald-muted)' : 'var(--accent-amber-muted)',
                        color: photoResult.confidence >= 0.7 ? 'var(--accent-emerald)' : 'var(--accent-amber)',
                      },
                    },
                    {
                      label: 'Nettete',
                      value: `${(photoResult.blur_score * 100).toFixed(0)}%`,
                      style: {
                        bg: photoResult.blur_score >= 0.35 ? 'var(--accent-emerald-muted)' : 'var(--accent-rose-muted)',
                        color: photoResult.blur_score >= 0.35 ? 'var(--accent-emerald)' : 'var(--accent-rose)',
                      },
                    },
                    {
                      label: 'Luminosite',
                      value: `${(photoResult.brightness * 100).toFixed(0)}%`,
                      style: {
                        bg: 'var(--accent-blue-muted)',
                        color: 'var(--accent-blue)',
                      },
                    },
                  ].map((metric) => (
                    <div
                      key={metric.label}
                      className="rounded-lg p-3 text-center"
                      style={{ background: 'var(--bg-raised)', border: '1px solid var(--border-strong)' }}
                    >
                      <p className="text-[10px] font-semibold uppercase tracking-[0.1em] mb-1" style={{ color: 'var(--text-muted)' }}>
                        {metric.label}
                      </p>
                      <span
                        className="rounded-md px-2 py-0.5 text-[13px] font-bold"
                        style={{ background: metric.style.bg, color: metric.style.color }}
                      >
                        {metric.value}
                      </span>
                    </div>
                  ))}
                </div>

                {/* Notes */}
                <div className="pt-3" style={{ borderTop: '1px solid var(--border-subtle)' }}>
                  <p className="text-[10px] font-semibold uppercase tracking-[0.1em] mb-2" style={{ color: 'var(--text-muted)' }}>Notes</p>
                  <ul className="space-y-1.5">
                    {photoResult.notes.map((note, i) => (
                      <li key={i} className="text-[12px] flex items-start gap-2" style={{ color: 'var(--text-secondary)' }}>
                        <span className="mt-1.5 h-1 w-1 rounded-full shrink-0" style={{ background: 'var(--text-muted)' }} />
                        {note}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default AIPage;
