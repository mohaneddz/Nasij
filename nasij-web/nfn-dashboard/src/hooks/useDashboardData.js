import { useCallback, useEffect, useMemo, useState } from 'react'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

function apiHeaders() {
  const token = localStorage.getItem('nfn_token')
  return {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  }
}

const WILAYA_COORDS = {
  'أدرار': [27.8742, -0.2946],
  'الشلف': [36.1648, 1.3317],
  'الأغواط': [33.8000, 2.8833],
  'أم البواقي': [35.8780, 7.1133],
  'باتنة': [35.5559, 6.1742],
  'بجاية': [36.7509, 5.0567],
  'بسكرة': [34.8500, 5.7333],
  'بشار': [31.6167, -2.2167],
  'البليدة': [36.4700, 2.8277],
  'البويرة': [36.3742, 3.9003],
  'تمنراست': [22.7851, 5.5228],
  'تبسة': [35.4041, 8.1196],
  'تلمسان': [34.8828, -1.3160],
  'تيارت': [35.3711, 1.3217],
  'تيزي وزو': [36.7169, 4.0497],
  'الجزائر': [36.7372, 3.0867],
  'الجلفة': [34.6747, 3.2628],
  'جيجل': [36.8200, 5.7667],
  'سطيف': [36.1898, 5.4108],
  'سعيدة': [34.8302, 0.1517],
  'سكيكدة': [36.8762, 6.9065],
  'سيدي بلعباس': [35.1895, -0.6314],
  'عنابة': [36.9000, 7.7667],
  'قالمة': [36.4620, 7.4281],
  'قسنطينة': [36.3650, 6.6147],
  'المدية': [36.2639, 2.7539],
  'مستغانم': [35.9314, 0.0892],
  'المسيلة': [35.7058, 4.5417],
  'معسكر': [35.3962, 0.1400],
  'ورقلة': [31.9539, 5.3246],
  'وهران': [35.6969, -0.6331],
  'البيض': [33.6843, 1.0039],
  'إليزي': [26.5000, 8.4667],
  'برج بوعريريج': [36.0728, 4.7617],
  'بومرداس': [36.7600, 3.4778],
  'الطارف': [36.7673, 8.3129],
  'تندوف': [27.6742, -8.1367],
  'تيسمسيلت': [35.6072, 1.8119],
  'الوادي': [33.3683, 6.8676],
  'خنشلة': [35.4356, 7.1453],
  'سوق أهراس': [36.2861, 7.9511],
  'تيبازة': [36.5889, 2.4466],
  'ميلة': [36.4507, 6.2647],
  'عين الدفلى': [36.2641, 1.9664],
  'النعامة': [33.2667, -0.3167],
  'عين تموشنت': [35.2972, -1.1408],
  'غرداية': [32.4908, 3.6737],
  'غليزان': [35.7378, 0.5564],
  'تيميمون': [29.2639, 0.2306],
  'برج باجي مختار': [21.3267, 0.9467],
  'أولاد جلال': [34.4186, 5.0686],
  'بني عباس': [30.1281, -2.1653],
  'عين صالح': [27.1958, 2.4833],
  'عين قزام': [19.5667, 5.7667],
  'تقرت': [33.1004, 6.0669],
  'جانت': [24.5553, 9.4844],
  'المغير': [33.9433, 5.9231],
  'المنيعة': [30.5833, 2.8833],
}

function resolveWilayaCoords(wilaya) {
  if (!wilaya) return null
  const normalized = wilaya.trim().replace(/\s+/g, ' ')
  if (WILAYA_COORDS[normalized]) return WILAYA_COORDS[normalized]
  const withoutAl = normalized.startsWith('ال') ? normalized.slice(2) : 'ال' + normalized
  return WILAYA_COORDS[withoutAl] || null
}

function mapBatch(row) {
  return {
    batchId: row.batch_id,
    sourceType: row.source_type,
    breed: row.breed,
    wilaya: row.wilaya,
    status: row.status,
    purchasePriceDzd: row.purchase_price_dzd,
    creatorId: row.creator_id,
    collectorId: row.collector_id,
    creatorPhone: row.creator_phone,
    collectorPhone: row.collector_phone,
    typeDeLaine: row.type_de_laine,
    propreteScore: row.proprete_score,
    sacsCount: row.sacs_count,
    weightRawE1Kg: row.weight_raw_e1_kg,
    weightAfterHandcleanKg: row.weight_after_handclean_kg,
    weightCleanD2Kg: row.weight_clean_d2_kg,
    yieldPercentage: row.yield_percentage,
    classification: row.classification,
    temperatureTasCelsius: row.temperature_tas_celsius,
    tauxMatiereVegetalePercent: row.taux_matiere_vegetale_percent,
    humiditeSortiePercent: row.humidite_sortie_percent,
    phLaine: row.ph_laine,
    fiberLengthMm: row.fiber_length_mm,
    finesseMicron: row.finesse_micron,
    humidityPercent: row.humidity_percent,
    finalDestination: row.final_destination,
    stockageZone: row.stockage_zone,
    locationLat: row.location_lat ?? (resolveWilayaCoords(row.wilaya)?.[0] ?? null),
    locationLng: row.location_lng ?? (resolveWilayaCoords(row.wilaya)?.[1] ?? null),
    locationIsGeocoded: row.location_lat == null && resolveWilayaCoords(row.wilaya) != null,
    annexMetadata: row.annex_metadata,
    actionTimestamp: row.action_timestamp,
    syncedAt: row.synced_at,
  }
}

function mapAlert(row, batchMeta) {
  return {
    id: row.id,
    batchId: row.batch_id,
    alertType: row.alert_type,
    description: row.description,
    createdAt: row.created_at,
    severity: row.severity || (row.alert_type?.includes('E1') ? 'POINT_NOIR' : 'POINT_ROUGE'),
    action: row.action || (row.alert_type?.includes('E1') ? 'Investigate Route' : 'Flag Supplier'),
    isResolved: Boolean(row.is_resolved),
    batchMeta,
  }
}

export function useDashboardData() {
  const [batches, setBatches] = useState([])
  const [alerts, setAlerts] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const fetchLive = useCallback(async () => {
    setLoading(true)
    setError('')

    try {
      const [batchesResponse, alertsResponse, usersResponse] = await Promise.all([
        fetch(`${API_URL}/api/batches`, { headers: apiHeaders() }),
        fetch(`${API_URL}/api/alerts`, { headers: apiHeaders() }),
        fetch(`${API_URL}/api/users`, { headers: apiHeaders() }),
      ])

      if (!batchesResponse.ok) throw new Error('Failed to fetch batches from backend')
      if (!alertsResponse.ok) throw new Error('Failed to fetch alerts from backend')
      if (!usersResponse.ok) throw new Error('Failed to fetch users from backend')

      const [batchesRows, alertsRows, usersRows] = await Promise.all([
        batchesResponse.json(),
        alertsResponse.json(),
        usersResponse.json(),
      ])

      const userById = (usersRows || []).reduce((acc, row) => {
        acc[row.id] = {
          id: row.id,
          phoneNumber: row.phone_number,
          fullName: row.full_name,
          sector: row.sector || row.role,
          wilaya: row.wilaya,
        }
        return acc
      }, {})

      const userByPhone = (usersRows || []).reduce((acc, row) => {
        if (!row.phone_number) return acc
        acc[row.phone_number] = {
          id: row.id,
          phoneNumber: row.phone_number,
          fullName: row.full_name,
          sector: row.sector || row.role,
          wilaya: row.wilaya,
        }
        return acc
      }, {})

      const mappedBatches = (batchesRows || [])
        .map((row) => {
          const batch = mapBatch(row)
          batch.creator = userById[row.creator_id] || userByPhone[row.creator_phone] || null
          batch.collector = userById[row.collector_id] || userByPhone[row.collector_phone] || null
          return batch
        })
        .filter((item) => typeof item.locationLat === 'number' && typeof item.locationLng === 'number')
        // locationIsGeocoded=true means coords came from wilaya lookup, map renders them with a different marker style

      const batchIndex = (batchesRows || []).reduce((acc, row) => {
        acc[row.batch_id] = {
          batchId: row.batch_id,
          wilaya: row.wilaya,
          sourceType: row.source_type,
          breed: row.breed,
          creator: userById[row.creator_id] || userByPhone[row.creator_phone] || null,
          collector: userById[row.collector_id] || userByPhone[row.collector_phone] || null,
        }
        return acc
      }, {})

      const mappedAlerts = (alertsRows || []).map((row) => mapAlert(row, batchIndex[row.batch_id]))

      setBatches(mappedBatches)
      setAlerts(mappedAlerts)
    } catch (err) {
      setError(err.message || 'Backend fetch failed, using mock data.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchLive()
    const timer = setInterval(fetchLive, 30000)

    return () => clearInterval(timer)
  }, [fetchLive])

  const source = useMemo(() => {
    if (error) return 'mock-fallback'
    return 'backend-live'
  }, [error])

  return {
    batches,
    alerts,
    loading,
    error,
    source,
  }
}
