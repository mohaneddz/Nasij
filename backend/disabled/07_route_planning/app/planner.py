from __future__ import annotations

from app.geo_utils import haversine_km
from app.schemas import Depot, Pickup


def greedy_pickup_order(start_lat: float, start_lon: float, pickups: list[Pickup]) -> list[Pickup]:
    remaining = pickups.copy()
    order: list[Pickup] = []
    cur_lat, cur_lon = start_lat, start_lon
    while remaining:
        nxt = min(remaining, key=lambda p: haversine_km(cur_lat, cur_lon, p.latitude, p.longitude))
        order.append(nxt)
        remaining.remove(nxt)
        cur_lat, cur_lon = nxt.latitude, nxt.longitude
    return order


def assign_depot(last_lat: float, last_lon: float, expected_load_kg: float, depots: list[Depot]) -> Depot:
    capable = [d for d in depots if d.remaining_capacity_kg >= expected_load_kg]
    candidates = capable if capable else depots
    return min(candidates, key=lambda d: haversine_km(last_lat, last_lon, d.latitude, d.longitude))

