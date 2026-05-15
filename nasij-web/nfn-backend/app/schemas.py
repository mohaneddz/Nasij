from enum import Enum
from datetime import datetime
from typing import Any, Optional
from pydantic import BaseModel, Field
from uuid import uuid4


# ── Enums ──────────────────────────────────────────────

class SectorRole(str, Enum):
    C1_FARMER = "C1_FARMER"
    C2_ABATTOIR = "C2_ABATTOIR"
    C3_AGGREGATOR = "C3_AGGREGATOR"
    DEPOT_WORKER = "DEPOT_WORKER"
    LAVAGE_WORKER = "LAVAGE_WORKER"
    TRANSFORMATEUR = "TRANSFORMATEUR"


class SheepBreed(str, Enum):
    OULED_DJELLAL = "OULED_DJELLAL"
    REMBI = "REMBI"
    EL_HAMRA = "EL_HAMRA"
    BARBAR = "BARBAR"
    TEZEGZAWET = "TEZEGZAWET"
    MIXTE = "MIXTE"


class BatchStatus(str, Enum):
    PENDING_PICKUP = "PENDING_PICKUP"
    COLLECTED_BY_BUYER = "COLLECTED_BY_BUYER"
    AT_D1_STOCKAGE = "AT_D1_STOCKAGE"
    AT_D2_LAVAGE = "AT_D2_LAVAGE"
    IN_TRANSFORMATION = "IN_TRANSFORMATION"
    READY_FOR_SALE = "READY_FOR_SALE"


class AlertSeverity(str, Enum):
    POINT_NOIR = "POINT_NOIR"
    POINT_ROUGE = "POINT_ROUGE"
    POINT_JAUNE = "POINT_JAUNE"


class WoolType(str, Enum):
    TOISON_ENTIERE = "TOISON_ENTIERE"
    TOISON_MORCEAUX = "TOISON_MORCEAUX"
    LAINE_QUEUE = "LAINE_QUEUE"
    PELADE_CHIMIQUE = "PELADE_CHIMIQUE"
    ECHAUFFEE_NATURELLE = "ECHAUFFEE_NATURELLE"


class WoolClass(str, Enum):
    CLASSE_A_PROPRE = "CLASSE_A_PROPRE"
    CLASSE_B_SOUILLEE = "CLASSE_B_SOUILLEE"
    D3 = "D3"
    D4 = "D4"


# ── Auth ───────────────────────────────────────────────

class AuthSignup(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)
    password: str = Field(..., min_length=4)
    sector: SectorRole
    wilaya: Optional[str] = None


class AuthLogin(BaseModel):
    phone: str
    password: str


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    user_id: str
    phone: str
    sector: Optional[str] = None
    wilaya: Optional[str] = None


class UserCreate(BaseModel):
    phone: str = Field(..., min_length=4, max_length=100)
    password: str = Field(..., min_length=4)
    full_name: str
    sector: SectorRole
    wilaya: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    phone_number: str
    full_name: Optional[str] = None
    sector: str
    wilaya: Optional[str] = None
    is_approved: bool
    created_at: Optional[datetime] = None


# ── Batches ────────────────────────────────────────────

class BatchCreate(BaseModel):
    batch_id: str = Field(..., description="QR code ID generated offline, e.g. NFN-1042")
    source_type: str = Field(..., description="C1, C2, or C3")
    breed: SheepBreed
    wilaya: str
    creator_phone: Optional[str] = None
    collector_phone: Optional[str] = None
    purchase_price_dzd: Optional[float] = None
    weight_raw_e1_kg: Optional[float] = None
    type_de_laine: Optional[WoolType] = None
    proprete_score: Optional[int] = Field(default=None, ge=1, le=5)
    sacs_count: Optional[int] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    action_timestamp: Optional[str] = None
    annex_metadata: Optional[dict[str, Any]] = None


class BatchUpdate(BaseModel):
    status: Optional[BatchStatus] = None
    weight_raw_e1_kg: Optional[float] = None
    weight_after_handclean_kg: Optional[float] = None
    weight_clean_d2_kg: Optional[float] = None
    stockage_zone: Optional[str] = None
    classification: Optional[WoolClass] = None
    temperature_tas_celsius: Optional[float] = None
    taux_matiere_vegetale_percent: Optional[float] = None
    humidite_sortie_percent: Optional[float] = None
    ph_laine: Optional[float] = None
    fiber_length_mm: Optional[float] = None
    finesse_micron: Optional[float] = None
    humidity_percent: Optional[float] = None
    final_destination: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    annex_metadata: Optional[dict[str, Any]] = None


class BatchResponse(BaseModel):
    batch_id: str
    source_type: Optional[str] = None
    breed: Optional[str] = None
    wilaya: Optional[str] = None
    creator_phone: Optional[str] = None
    collector_phone: Optional[str] = None
    status: Optional[str] = None
    purchase_price_dzd: Optional[float] = None
    type_de_laine: Optional[str] = None
    proprete_score: Optional[int] = None
    sacs_count: Optional[int] = None
    weight_raw_e1_kg: Optional[float] = None
    weight_after_handclean_kg: Optional[float] = None
    weight_clean_d2_kg: Optional[float] = None
    stockage_zone: Optional[str] = None
    classification: Optional[str] = None
    temperature_tas_celsius: Optional[float] = None
    taux_matiere_vegetale_percent: Optional[float] = None
    humidite_sortie_percent: Optional[float] = None
    ph_laine: Optional[float] = None
    fiber_length_mm: Optional[float] = None
    finesse_micron: Optional[float] = None
    humidity_percent: Optional[float] = None
    final_destination: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    annex_metadata: Optional[dict[str, Any]] = None
    action_timestamp: Optional[str] = None
    synced_at: Optional[str] = None


# ── Alerts ─────────────────────────────────────────────

class AlertCreate(BaseModel):
    batch_id: str
    alert_type: str
    description: str
    severity: AlertSeverity = AlertSeverity.POINT_ROUGE


class AlertResponse(BaseModel):
    id: str
    batch_id: Optional[str] = None
    alert_type: Optional[str] = None
    description: Optional[str] = None
    severity: Optional[str] = None
    is_resolved: bool = False
    action: Optional[str] = None
    created_at: Optional[str] = None


# ── Dashboard ──────────────────────────────────────────

class DashboardKPIs(BaseModel):
    volume_declared_kg: float
    volume_received_kg: float
    loss_percent: float
    average_yield: float
    active_alerts: int
    total_batches: int
    batches_by_status: dict[str, int]


class BreedDistribution(BaseModel):
    breed: str
    count: int
    percentage: float


class QualitySplit(BaseModel):
    d3_count: int
    d4_count: int
    d3_percent: float
    d4_percent: float


# ── Sync ───────────────────────────────────────────────

class SyncBatchItem(BaseModel):
    batch_id: str
    source_type: str
    breed: SheepBreed
    wilaya: str
    status: BatchStatus = BatchStatus.PENDING_PICKUP
    creator_phone: Optional[str] = None
    collector_phone: Optional[str] = None
    purchase_price_dzd: Optional[float] = None
    type_de_laine: Optional[WoolType] = None
    proprete_score: Optional[int] = Field(default=None, ge=1, le=5)
    sacs_count: Optional[int] = None
    weight_raw_e1_kg: Optional[float] = None
    weight_after_handclean_kg: Optional[float] = None
    weight_clean_d2_kg: Optional[float] = None
    stockage_zone: Optional[str] = None
    classification: Optional[WoolClass] = None
    temperature_tas_celsius: Optional[float] = None
    taux_matiere_vegetale_percent: Optional[float] = None
    humidite_sortie_percent: Optional[float] = None
    ph_laine: Optional[float] = None
    fiber_length_mm: Optional[float] = None
    finesse_micron: Optional[float] = None
    humidity_percent: Optional[float] = None
    final_destination: Optional[str] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    action_timestamp: Optional[str] = None
    annex_metadata: Optional[dict[str, Any]] = None


class SyncPayload(BaseModel):
    device_id: str
    items: list[SyncBatchItem]


class SyncResult(BaseModel):
    synced: int
    failed: int
    errors: list[str]
