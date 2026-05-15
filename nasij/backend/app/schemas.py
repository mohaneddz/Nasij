from enum import Enum
from datetime import datetime
from typing import Any, Optional
from pydantic import BaseModel, Field


# ── Enums ──────────────────────────────────────────────

class SectorRole(str, Enum):
    C1_FARMER = "C1_FARMER"
    C2_ABATTOIR = "C2_ABATTOIR"
    C3_AGGREGATOR = "C3_AGGREGATOR"
    COLLECTOR = "COLLECTOR"
    WORKER = "WORKER"
    MANAGER = "MANAGER"
    DEPOT_WORKER = "DEPOT_WORKER"
    LAVAGE_WORKER = "LAVAGE_WORKER"
    TRANSFORMATEUR = "TRANSFORMATEUR"


class SupplierRole(str, Enum):
    farmer = "farmer"
    producer = "producer"
    slaughterhouse = "slaughterhouse"


class SupplierApprovalStatus(str, Enum):
    PENDING_APPROVAL = "PENDING_APPROVAL"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class SupplierOperationStatus(str, Enum):
    PENDING = "PENDING"
    ASSIGNED = "ASSIGNED"
    CANCELLED_PENDING = "CANCELLED_PENDING"
    CANCELLED_ASSIGNED = "CANCELLED_ASSIGNED"
    COMPLETED = "COMPLETED"


class SourceEnum(str, Enum):
    C1 = "C1"
    C2 = "C2"
    C3 = "C3"


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


class WoolType(str, Enum):
    TOISON_ENTIERE = "TOISON_ENTIERE"
    TOISON_MORCEAUX = "TOISON_MORCEAUX"
    LAINE_QUEUE = "LAINE_QUEUE"
    PELADE_CHIMIQUE = "PELADE_CHIMIQUE"
    ECHAUFFEE_NATURELLE = "ECHAUFFEE_NATURELLE"


class WoolClass(str, Enum):
    CLASSE_A_PROPRE = "CLASSE_A_PROPRE"
    CLASSE_B_SOUILLEE = "CLASSE_B_SOUILLEE"


class AlertSeverity(str, Enum):
    POINT_NOIR = "POINT_NOIR"
    POINT_ROUGE = "POINT_ROUGE"
    POINT_JAUNE = "POINT_JAUNE"


# ── Auth ───────────────────────────────────────────────

class AuthSignup(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)
    password: str = Field(..., min_length=4)
    sector: SectorRole
    full_name: Optional[str] = None
    wilaya: Optional[str] = None


class AuthLogin(BaseModel):
    phone: str
    password: str


class AuthRefresh(BaseModel):
    refresh_token: str


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    user_id: str
    phone: str
    sector: Optional[str] = None
    wilaya: Optional[str] = None
    full_name: Optional[str] = None


class EmployeeLoginBody(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)
    password: str


class EmployeeAuthResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    user_id: str
    phone: str
    sector: Optional[str] = None
    full_name: Optional[str] = None


class MeResponse(BaseModel):
    id: str
    phone: str
    sector: Optional[str] = None
    wilaya: Optional[str] = None
    full_name: Optional[str] = None


class SupplierOtpRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)
    supplier_role: SupplierRole
    full_name: Optional[str] = None
    wilaya: Optional[str] = None


class SupplierOtpRequestResponse(BaseModel):
    cooldown_seconds: int = 60
    is_new_supplier: bool


class SupplierOtpVerify(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)
    supplier_role: SupplierRole
    otp_code: str = Field(..., min_length=6, max_length=6)
    full_name: Optional[str] = None
    wilaya: Optional[str] = None


class SupplierAuthResponse(BaseModel):
    approval_status: SupplierApprovalStatus
    message: Optional[str] = None
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    user_id: Optional[str] = None
    phone: str
    sector: Optional[str] = None
    wilaya: Optional[str] = None
    full_name: Optional[str] = None
    trust_score: int = 100


class SupplierProfileResponse(BaseModel):
    id: str
    phone: str
    full_name: Optional[str] = None
    sector: Optional[str] = None
    wilaya: Optional[str] = None
    approval_status: SupplierApprovalStatus
    trust_score: int = 100


class SupplierDeclarationBody(BaseModel):
    quantity_count: Optional[int] = Field(default=None, ge=1)
    quantity_weight_kg: Optional[float] = Field(default=None, gt=0)
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None


class SupplierOperationResponse(BaseModel):
    id: str
    supplier_id: str
    supplier_phone: str
    supplier_role: str
    status: SupplierOperationStatus
    quantity_count: Optional[int] = None
    quantity_weight_kg: Optional[float] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    collector_id: Optional[str] = None
    collector_phone: Optional[str] = None
    cancel_reason: Optional[str] = None
    cancelled_at: Optional[str] = None
    trust_penalty_applied: int = 0
    trust_score_after: Optional[int] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class SupplierOperationCancelBody(BaseModel):
    reason: Optional[str] = None
    call_confirmed: bool = False


class SupplierApprovalActionBody(BaseModel):
    note: Optional[str] = None


class SupplierApprovalQueueItem(BaseModel):
    id: str
    phone: str
    full_name: Optional[str] = None
    sector: Optional[str] = None
    wilaya: Optional[str] = None
    approval_status: SupplierApprovalStatus
    approval_requested_at: Optional[str] = None
    approval_decided_at: Optional[str] = None
    approval_note: Optional[str] = None
    trust_score: int = 100


# ── Batch lifecycle bodies ─────────────────────────────

class CreateBatchBody(BaseModel):
    """Posted by C1/C2/C3 when creating a new collection request."""
    batch_id: str = Field(..., description="Offline-generated ID, e.g. NFN-2026-001")
    source_type: SourceEnum
    breed: SheepBreed
    wilaya: str
    type_de_laine: Optional[WoolType] = None
    # C1: number of sheep
    estimated_sheep_count: Optional[int] = None
    # C2: skin condition notes
    skin_condition: Optional[str] = None
    # C3: number of bags
    estimated_bags_count: Optional[int] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    action_timestamp: Optional[str] = None
    annex_metadata: Optional[dict[str, Any]] = None


class CollectBody(BaseModel):
    """Posted by Collector after weighing and negotiating at the source."""
    collector_id: Optional[str] = None
    purchase_price_dzd: float
    weight_raw_e1_kg: float = Field(..., gt=0)
    sacs_count: Optional[int] = None
    proprete_score: Optional[int] = Field(default=None, ge=1, le=5)
    type_de_laine: Optional[WoolType] = None
    action_timestamp: Optional[str] = None


class D1IntakeBody(BaseModel):
    """Depot D1 worker scans QR and records actual received weight."""
    weight_received_d1_kg: float = Field(..., gt=0)
    stockage_zone: Optional[str] = None
    action_timestamp: Optional[str] = None


class D1CleanBody(BaseModel):
    """Depot D1 worker records post-cleaning weight and vegetable matter."""
    weight_after_handclean_kg: float = Field(..., gt=0)
    waste_removed_kg: Optional[float] = Field(default=None, ge=0)
    skin_removed_kg: Optional[float] = Field(default=None, ge=0)
    taux_matiere_vegetale_percent: Optional[float] = Field(default=None, ge=0, le=100)
    classification: Optional[WoolClass] = None
    temperature_tas_celsius: Optional[float] = None
    action_timestamp: Optional[str] = None


class D2WashBody(BaseModel):
    """Washer records wash parameters and routes batch to D3 or D4."""
    weight_clean_d2_kg: float = Field(..., gt=0)
    water_temp_celsius: Optional[float] = None
    detergent_type: Optional[str] = None
    humidite_sortie_percent: Optional[float] = Field(default=None, ge=0, le=100)
    ph_laine: Optional[float] = None
    final_destination: str = Field(..., description="D3_TEXTILES or D4_ENGRAIS")
    action_timestamp: Optional[str] = None


class TransformIntakeBody(BaseModel):
    """Factory intake records received weight and checks against washer declared weight."""
    weight_received_factory_kg: float = Field(..., gt=0)
    action_timestamp: Optional[str] = None


class TransformBody(BaseModel):
    """Factory transformer records final product metrics and seals the batch."""
    product_type: str
    fiber_length_mm: Optional[float] = None
    finesse_micron: Optional[float] = None
    humidity_percent: Optional[float] = Field(default=None, ge=0, le=100)
    target_density_kg_m3: Optional[float] = None
    total_units_produced: Optional[int] = None
    total_finished_weight_kg: Optional[float] = None
    action_timestamp: Optional[str] = None


# ── Batch response ─────────────────────────────────────

class BatchResponse(BaseModel):
    batch_id: str
    source_type: Optional[str] = None
    breed: Optional[str] = None
    wilaya: Optional[str] = None
    status: Optional[str] = None
    creator_id: Optional[str] = None
    creator_phone: Optional[str] = None
    creator_full_name: Optional[str] = None
    collector_id: Optional[str] = None
    collector_phone: Optional[str] = None
    collector_full_name: Optional[str] = None
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
    is_ready_for_sale: Optional[bool] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    waste_removed_kg: Optional[float] = None
    skin_removed_kg: Optional[float] = None
    annex_metadata: Optional[dict[str, Any]] = None
    action_timestamp: Optional[str] = None
    synced_at: Optional[str] = None
    created_at: Optional[str] = None


# ── Alert ──────────────────────────────────────────────

class AlertResponse(BaseModel):
    id: str
    batch_id: Optional[str] = None
    alert_type: Optional[str] = None
    severity: Optional[str] = None
    description: Optional[str] = None
    action: Optional[str] = None
    is_resolved: bool = False
    created_at: Optional[str] = None


# ── Offline sync ───────────────────────────────────────

class SyncItem(BaseModel):
    """One queued action from the device's offline outbox."""
    batch_id: str
    source_type: SourceEnum
    breed: SheepBreed
    wilaya: str
    status: BatchStatus = BatchStatus.PENDING_PICKUP
    creator_id: Optional[str] = None
    collector_id: Optional[str] = None
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
    is_ready_for_sale: Optional[bool] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    action_timestamp: Optional[str] = None
    annex_metadata: Optional[dict[str, Any]] = None


class SyncPayload(BaseModel):
    device_id: str
    items: list[SyncItem]


class SyncResult(BaseModel):
    synced: int
    failed: int
    errors: list[str]


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


# ── Staff / Users (web dashboard) ─────────────────────

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
    is_approved: bool = False
    created_at: Optional[datetime] = None
