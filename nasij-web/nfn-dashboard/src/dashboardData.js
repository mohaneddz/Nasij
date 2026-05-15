export const navItems = [
  { path: '/', label: 'Tableau de Bord' },
  { path: '/map', label: 'Cartographie Live' },
  { path: '/pipeline', label: 'Flux NFN' },
  { path: '/alerts', label: 'Centre de Controle' },
  { path: '/certification', label: 'Sceau & Export' },
]

export const pipelineColumns = [
  {
    key: 'COLLECTE',
    title: 'En Attente (Collecte)',
    accent: '#2e7d32',
    statuses: ['PENDING_PICKUP', 'COLLECTED_BY_BUYER'],
  },
  {
    key: 'D1',
    title: 'Depot D1 (Tri)',
    accent: '#ed6c02',
    statuses: ['AT_D1_STOCKAGE'],
  },
  {
    key: 'D2',
    title: 'Lavage (D2)',
    accent: '#1565c0',
    statuses: ['AT_D2_LAVAGE'],
  },
  {
    key: 'TRANSFORMATION',
    title: 'Transformation',
    accent: '#6a1b9a',
    statuses: ['IN_TRANSFORMATION', 'READY_FOR_SALE'],
  },
]

export function toTonnes(valueKg) {
  return `${(valueKg / 1000).toFixed(1)} t`
}

export function getYield(weightCleanD2Kg, weightAfterHandcleanKg) {
  if (!weightCleanD2Kg || !weightAfterHandcleanKg) return null
  return Number(((weightCleanD2Kg / weightAfterHandcleanKg) * 100).toFixed(1))
}

export function getKpiMetrics(currentBatches = [], currentAlerts = []) {
  const declared = currentBatches.reduce((sum, batch) => sum + (batch.weightRawE1Kg || 0), 0)
  const received = currentBatches.reduce((sum, batch) => sum + (batch.weightAfterHandcleanKg || 0), 0)

  const yields = currentBatches
    .map((batch) => getYield(batch.weightCleanD2Kg, batch.weightAfterHandcleanKg))
    .filter((value) => typeof value === 'number')

  const averageYield = yields.length
    ? (yields.reduce((sum, item) => sum + item, 0) / yields.length).toFixed(1)
    : '0.0'

  const lossPercent = declared > 0 ? (((declared - received) / declared) * 100).toFixed(1) : '0.0'

  return {
    declared,
    received,
    averageYield,
    activeAlerts: currentAlerts.filter((item) => !item.isResolved).length,
    lossPercent,
  }
}

function getBatchYield(batch) {
  if (typeof batch.yieldPercentage === 'number') return batch.yieldPercentage
  if (batch.weightCleanD2Kg && batch.weightRawE1Kg) {
    return Number(((batch.weightCleanD2Kg / batch.weightRawE1Kg) * 100).toFixed(1))
  }
  return null
}

function getAverageSourceYield(currentBatches, sourceType) {
  const yields = currentBatches
    .filter((batch) => batch.sourceType === sourceType)
    .map(getBatchYield)
    .filter((value) => typeof value === 'number')

  if (!yields.length) return '0.0'
  return (yields.reduce((sum, value) => sum + value, 0) / yields.length).toFixed(1)
}

export function getAnnexKpis(currentBatches = []) {
  return {
    tonteYield: getAverageSourceYield(currentBatches, 'C1'),
    tonteTarget: '55-65%',
    abattageYield: getAverageSourceYield(currentBatches, 'C2'),
    abattageTarget: '35-45%',
  }
}

export function getClassDistributionData(currentBatches = []) {
  const classified = currentBatches.filter((batch) => batch.classification)

  if (!classified.length) return { classA: 0, classB: 0 }

  const classA = classified.filter((batch) => batch.classification === 'CLASSE_A_PROPRE').length
  const classB = classified.filter((batch) => batch.classification === 'CLASSE_B_SOUILLEE').length
  const total = classA + classB || 1

  return {
    classA: Math.round((classA / total) * 100),
    classB: Math.round((classB / total) * 100),
  }
}

export const sourceLabels = {
  C1: 'Tonte (C1)',
  C2: 'Abattage (C2)',
  C3: 'Agregateur (C3)',
}

export const breedLabels = {
  OULED_DJELLAL: 'Ouled Djellal',
  REMBI: 'Rembi',
  EL_HAMRA: 'El Hamra',
  BARBAR: 'Barbar',
  TEZEGZAWET: 'Tezegzawet',
  MIXTE: 'Mixte',
}

export const woolTypeLabels = {
  TOISON_ENTIERE: 'Toison entiere',
  TOISON_MORCEAUX: 'Toison morceaux',
  LAINE_QUEUE: 'Laine de queue',
  PELADE_CHIMIQUE: 'Pelade chimique',
  ECHAUFFEE_NATURELLE: 'Echauffee naturelle',
}

export const woolClassLabels = {
  CLASSE_A_PROPRE: 'Classe A - Propre',
  CLASSE_B_SOUILLEE: 'Classe B - Souillee',
}

export function getBatchAnnexDetails(batch) {
  return {
    typeDeLaine: batch?.typeDeLaine,
    propreteScore: batch?.propreteScore,
    sacsCount: batch?.sacsCount,
    classification: batch?.classification,
    temperatureTasCelsius: batch?.temperatureTasCelsius,
    tauxMatiereVegetalePercent: batch?.tauxMatiereVegetalePercent,
    humiditeSortiePercent: batch?.humiditeSortiePercent,
    phLaine: batch?.phLaine,
    annexMetadata: batch?.annexMetadata || {},
  }
}

export function getBreedDistributionData(currentBatches = []) {
  const grouped = currentBatches.reduce((acc, batch) => {
    if (!acc[batch.breed]) acc[batch.breed] = 0
    acc[batch.breed] += 1
    return acc
  }, {})

  const total = currentBatches.length || 1

  return Object.entries(grouped).map(([breed, count]) => ({
    breed,
    value: Number(((count / total) * 100).toFixed(1)),
  }))
}

export function getFiberQualityData() {
  return [
    {
      destination: 'D3 Textiles',
      score: 82,
    },
    {
      destination: 'D4 Bio-fertilisants',
      score: 54,
    },
  ]
}
