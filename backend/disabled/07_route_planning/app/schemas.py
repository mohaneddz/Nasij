from pydantic import BaseModel, Field


class Pickup(BaseModel):
    request_id: str
    latitude: float
    longitude: float
    estimated_weight_kg: float = Field(gt=0)


class Depot(BaseModel):
    depot_id: str
    latitude: float
    longitude: float
    remaining_capacity_kg: float = Field(ge=0)


class RoutePayload(BaseModel):
    start_latitude: float
    start_longitude: float
    truck_capacity_kg: float = Field(gt=0)
    road_quality_index: float = Field(default=0.7, ge=0.1, le=1.0)
    pickups: list[Pickup]
    depots: list[Depot]


class RouteStop(BaseModel):
    request_id: str
    order: int
    eta_min_from_start: int


class RouteResponse(BaseModel):
    total_distance_km: float
    estimated_duration_min: int
    expected_load_kg: float
    assigned_depot: str
    stops: list[RouteStop]

