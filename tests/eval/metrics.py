"""
Run: pytest tests/eval/metrics.py -s  OR  PYTHONPATH=. python tests/eval/metrics.py

Ranking quality metrics for parking meter recommendations.
Uses golden LADOT snapshots (tests/eval/golden/) as ground truth.

Relevance rubric (see _relevance_score):
  3 = ideal   — very cheap (≤25% of budget), very close (≤75 m), time ≥ stay length
  2 = great   — cheap (≤50% of budget), close (≤150 m)
  1 = usable  — within budget and walkable (≤400 m)
  0 = poor    — over budget OR too far (>400 m)
"""

import json
import math
from pathlib import Path
from typing import List, Callable
from datetime import datetime

from src.services.ranking import MeterRanker
from src.utils.parsers import clean_data
from src.models.user import UserQuery, Location, UserPreferences, BudgetRange, StayTime
from src.models.meter import OccupancyStatus
from src.models.raw_api import RawMeterInventory, RawMeterOccupancy, RawLatLng


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------

def dcg_at_k(ranked_meters: List[float], k: int) -> float:
    """Helper for NDCG. DCG = Σ rel_i / log₂(i + 2)"""
    return sum(rel / math.log2(i + 2) for i, rel in enumerate(ranked_meters[:k]))


def ndcg_at_k(ranked_meters: List[float], k: int) -> float:
    """Are the best meters ranked first?  NDCG@K = DCG@K / ideal_DCG@K"""
    actual = dcg_at_k(ranked_meters, k)
    ideal = dcg_at_k(sorted(ranked_meters, reverse=True), k)
    return actual / ideal if ideal else 0.0


def ap_at_k(ranked_meters: List[float], k: int, threshold: float = 1.0) -> float:
    """Are relevant meters packed at the top?  AP = (1/|rel|) Σ hits/pos"""
    hits = 0
    total = 0.0
    for i, rel in enumerate(ranked_meters[:k]):
        if rel >= threshold:
            hits += 1
            total += hits / (i + 1)
    return total / hits if hits else 0.0


def mrr_at_k(ranked_meters: List[float], k: int, threshold: float = 1.0) -> float:
    """How fast does the user see a usable meter?  RR = 1/rank_first_relevant"""
    for i, rel in enumerate(ranked_meters[:k]):
        if rel >= threshold:
            return 1.0 / (i + 1)
    return 0.0


def precision_at_k(ranked_meters: List[float], k: int, threshold: float = 1.0) -> float:
    """What fraction of top-K are usable?  P@K = |rel ∩ top-K| / K"""
    top = ranked_meters[:k]
    return sum(1 for r in top if r >= threshold) / k if top else 0.0


def _mean(fn: Callable, per_query: List[List[float]], k: int) -> float:
    """Average any per-query metric across all queries."""
    return sum(fn(q, k) for q in per_query) / len(per_query) if per_query else 0.0


# ---------------------------------------------------------------------------
# Relevance rubric (independent of ranker's scoring formula)
# ---------------------------------------------------------------------------

def _relevance_score(meter, budget: BudgetRange, stay: StayTime) -> int:
    max_budget = budget.value[1]
    cost = meter.estimated_total_cost
    dist = meter.distance_to_destination_meters

    if cost > max_budget or dist > 400:
        return 0
    if cost <= max_budget * 0.25 and dist <= 75 and meter.time_limit_minutes >= stay.value[1]:
        return 3
    if cost <= max_budget * 0.50 and dist <= 150:
        return 2
    return 1


# ---------------------------------------------------------------------------
# Golden data loader
# ---------------------------------------------------------------------------

GOLDEN_DIR = Path(__file__).parent / "golden"
DESTINATION = Location(lat=34.1016, lon=-118.3267)
K = 5


def _load_candidates():
    with open(GOLDEN_DIR / "meters.json") as f:
        raw_meters = json.load(f)
    with open(GOLDEN_DIR / "occupancy.json") as f:
        raw_occ = {r["spaceid"]: r for r in json.load(f)}

    candidates = []
    for m in raw_meters:
        inv = RawMeterInventory(
            spaceid=m["spaceid"], blockface=m["blockface"],
            metertype=m["metertype"], ratetype=m["ratetype"],
            raterange=m["raterange"], timelimit=m["timelimit"],
            latlng=RawLatLng(m["latlng"]["latitude"], m["latlng"]["longitude"]),
        )
        occ_raw = raw_occ.get(m["spaceid"])
        occ = RawMeterOccupancy(
            spaceid=occ_raw["spaceid"],
            eventtime=occ_raw.get("eventtime", ""),
            occupancystate=occ_raw.get("occupancystate", "UNKNOWN"),
        ) if occ_raw else None

        parsed = clean_data(inv, occ)
        if parsed.occupancy != OccupancyStatus.OCCUPIED:
            candidates.append(parsed)

    return candidates


QUERIES = [
    ("Q1  LOW / SHORT",     UserPreferences(BudgetRange.LOW,    StayTime.SHORT)),
    ("Q2  HIGH / LONG",     UserPreferences(BudgetRange.HIGH,   StayTime.LONG)),
    ("Q3  MEDIUM / MEDIUM", UserPreferences(BudgetRange.MEDIUM, StayTime.MEDIUM)),
    ("Q4  LOW / LONG",      UserPreferences(BudgetRange.LOW,    StayTime.LONG)),     # hardest: tight budget + long stay
    ("Q5  HIGH / SHORT",    UserPreferences(BudgetRange.HIGH,   StayTime.SHORT)),    # easiest: generous budget + quick stop
]


# ---------------------------------------------------------------------------
# Report helpers
# ---------------------------------------------------------------------------

def _print_query(label, prefs, results, scores):
    print(f"\n{label}  (max ${prefs.budget_range.value[1]}, {prefs.stay_time.value[1]} min)")
    print(f"  {'Rank':<5} {'ID':<8} {'$/hr':>5} {'Dist':>6} {'Time':>5} {'Cost':>6} {'Rel':>4}")
    print(f"  {'-'*40}")
    for m, r in zip(results, scores):
        print(f"  {m.rank:<5} {m.spaceid:<8} ${m.rate_per_hour:>4.2f} "
              f"{m.distance_to_destination_meters:>5.0f}m {m.time_limit_minutes:>4}m "
              f"${m.estimated_total_cost:>5.02f}   {r}")


def _print_aggregate(all_scores, k):
    metrics = [("NDCG", ndcg_at_k), ("MAP", ap_at_k), ("MRR", mrr_at_k), ("Precision", precision_at_k)]
    print(f"\n{'='*40}")
    print(f"  Aggregate  (k={k}, {len(all_scores)} queries)")
    print(f"{'='*40}")
    for name, fn in metrics:
        print(f"  {name + '@' + str(k):<20} {_mean(fn, all_scores, k):>8.4f}")


# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------

def test_metrics():
    candidates = _load_candidates()
    print(f"\nLoaded {len(candidates)} non-occupied meters from golden snapshot")

    ranker = MeterRanker()
    all_scores = []

    for label, prefs in QUERIES:
        query = UserQuery(
            current_location=Location(0, 0), current_time=datetime.now(),
            target_location_address="Hollywood & Vine",
            preferences=prefs,
        )
        results = ranker.rank_meters(candidates, query, DESTINATION, top_k=K)
        scores = [_relevance_score(m, prefs.budget_range, prefs.stay_time) for m in results]
        all_scores.append(scores)
        _print_query(label, prefs, results, scores)

    _print_aggregate(all_scores, K)


if __name__ == "__main__":
    test_metrics()
