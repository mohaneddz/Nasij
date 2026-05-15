from fastapi import FastAPI

from app.geo_utils import haversine_km
from app.modeling import DurationModel
from app.planner import assign_depot, greedy_pickup_order
from app.schemas import RoutePayload, RouteResponse, RouteStop

app = FastAPI(title="Route Planning Service", version="0.1.0")
duration_model = DurationModel()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/plan-route", response_model=RouteResponse)
def plan_route(payload: RoutePayload) -> RouteResponse:
    ordered = greedy_pickup_order(payload.start_latitude, payload.start_longitude, payload.pickups)
    total_distance = 0.0
    elapsed_min = 0.0
    expected_load = min(sum(p.estimated_weight_kg for p in ordered), payload.truck_capacity_kg)
    stops: list[RouteStop] = []

    cur_lat, cur_lon = payload.start_latitude, payload.start_longitude
    for idx, pickup in enumerate(ordered, start=1):
        segment = haversine_km(cur_lat, cur_lon, pickup.latitude, pickup.longitude)
        total_distance += segment
        load_ratio = min(1.0, expected_load / payload.truck_capacity_kg)
        elapsed_min += duration_model.predict_minutes(segment, load_ratio, payload.road_quality_index)
        stops.append(RouteStop(request_id=pickup.request_id, order=idx, eta_min_from_start=int(round(elapsed_min))))
        cur_lat, cur_lon = pickup.latitude, pickup.longitude

    depot = assign_depot(cur_lat, cur_lon, expected_load, payload.depots)
    to_depot_km = haversine_km(cur_lat, cur_lon, depot.latitude, depot.longitude)
    total_distance += to_depot_km
    elapsed_min += duration_model.predict_minutes(to_depot_km, expected_load / payload.truck_capacity_kg, payload.road_quality_index)

    return RouteResponse(
        total_distance_km=round(total_distance, 2),
        estimated_duration_min=int(round(elapsed_min)),
        expected_load_kg=round(expected_load, 2),
        assigned_depot=depot.depot_id,
        stops=stops,
    )

