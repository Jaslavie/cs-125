#assumes retrieval already returned valid CandidateMeter objects

# src/services/ranking.py

"""
Ranking and scoring logic for parking meters
Scores meters based on user preferences (budget, distance, stay time)
"""

from typing import List
from src.models.user import UserQuery, BudgetRange, StayTime, Location
from src.models.meter import CandidateMeter, OutputMeter
from src.services.api_distance import get_walking_route
from src.utils.haversine import haversine_distance

# Proportion of the distance score derived from each component.
# DEST_DISTANCE_WEIGHT governs meter→destination (the walk the user takes after parking)
# and is weighted heavily because proximity to the destination is the primary concern.
# USER_DISTANCE_WEIGHT governs user→meter (the drive the user takes to reach the spot)
# and acts as a tiebreaker that favors spots closer to the user's current location.
# The two constants must sum to 1.0.
DEST_DISTANCE_WEIGHT = 0.85
USER_DISTANCE_WEIGHT = 0.15


class MeterRanker:
    """Ranks parking meters based on user preferences and location context.
    """

    def __init__(self):
        # Define preference weights for different user profiles
        self.budget_weights = {
            BudgetRange.LOW: {"cost": 0.7, "distance": 0.2, "time": 0.1},
            BudgetRange.MEDIUM: {"cost": 0.5, "distance": 0.4, "time": 0.1},
            BudgetRange.HIGH: {"cost": 0.2, "distance": 0.6, "time": 0.2},
        }

        self.stay_time_weights = {
            StayTime.SHORT: {"time": 0.3, "distance": 0.5, "cost": 0.2},
            StayTime.MEDIUM: {"time": 0.4, "distance": 0.3, "cost": 0.3},
            StayTime.LONG: {"time": 0.5, "distance": 0.2, "cost": 0.3},
        }

    def rank_meters(
        self,
        candidates: List[CandidateMeter],
        user_query: UserQuery,
        destination: Location,
        top_k: int = 10
    ) -> List[OutputMeter]:
        """
        Main ranking pipeline:
        1. Compute meter→destination (OSRM) and user→meter (Haversine) distances.
        2. Blend distances: 85% destination-based, 15% user-proximity-based.
        3. Score each meter (cost, blended distance, time limit) with penalties, not hard filtering.
        4. Sort by score descending.
        5. Return top k as OutputMeters with rank assigned.
        """
        if not candidates:
            return []

        # Score each meter
        scored_meters = []
        for meter in candidates:
            # Primary: real walking distance from meter to destination (85% influence)
            dest_route = get_walking_route(meter.location, destination)

            # Secondary: straight-line distance from user to meter (15% influence)
            user_to_meter = haversine_distance(user_query.current_location, meter.location)

            # Blend: 85% destination-based, 15% user-proximity-based
            blended_distance = (DEST_DISTANCE_WEIGHT * dest_route["distance_meters"]) + (USER_DISTANCE_WEIGHT * user_to_meter)

            score = self._calculate_score(meter, user_query, blended_distance)
            scored_meters.append({
                "meter": meter,
                "score": score,
                "route": dest_route  # keep full route for walk_time_minutes in OutputMeter
            })

        # Sort by score (highest first)
        scored_meters.sort(key=lambda x: x["score"], reverse=True)

        # Convert to OutputMeter with rank
        output_meters = []
        for rank, item in enumerate(scored_meters[:top_k], start=1):
            output_meter = self._to_output_meter(item["meter"], rank, item["route"], user_query)
            output_meters.append(output_meter)

        return output_meters

    def _calculate_score(
        self,
        meter: CandidateMeter,
        query: UserQuery,
        distance: float,
    ) -> float:
        """Calculate weighted score for a meter (0-1 scale).
        """

        # Get weights based on user preferences
        budget_w = self.budget_weights[query.preferences.budget_range]
        stay_w = self.stay_time_weights[query.preferences.stay_time]

        # Combine weights (average of budget and stay time preferences)
        weights = {
            "cost": (budget_w["cost"] + stay_w["cost"]) / 2,
            "distance": (budget_w["distance"] + stay_w["distance"]) / 2,
            "time": (budget_w["time"] + stay_w["time"]) / 2,
        }

        # Calculate component scores (with penalties, not filtering)
        cost_score = self._score_cost(meter, query)
        distance_score = self._score_distance(distance)
        time_score = self._score_time_limit(meter, query)

        # Weighted combination
        final_score = (
            weights["cost"] * cost_score +
            weights["distance"] * distance_score +
            weights["time"] * time_score
        )

        return final_score

    def _score_cost(self, meter: CandidateMeter, query: UserQuery) -> float:
        """Score based on cost - cheaper is better (0-1 scale, with penalty for over-budget)"""
        stay_minutes = self._get_stay_duration_minutes(query.preferences.stay_time)
        total_cost = self._calculate_total_cost(meter, stay_minutes)
        max_budget = self._get_max_budget(query.preferences.budget_range)

        if max_budget == 0:
            return 1.0

        # Linear scaling with penalty for exceeding budget
        if total_cost <= max_budget:
            # Within budget: 0 cost = 1.0, max budget = 0.0
            score = 1.0 - (total_cost / max_budget)
        else:
            # Over budget: penalty proportional to how much over
            overage_ratio = (total_cost - max_budget) / max_budget
            score = -0.5 * overage_ratio  # Negative score, worse as overage increases

        return score

    def _score_distance(self, distance: float) -> float:
        """Score based on walking distance - closer is better (0-1 scale, with penalty for far)"""
        max_distance_m = 800  # meters (~10 min walk)

        if distance <= max_distance_m:
            # Within acceptable range: 0m = 1.0, 800m = 0.0
            score = 1.0 - (distance / max_distance_m)
        else:
            # Beyond acceptable range: penalty proportional to how far beyond
            excess_ratio = (distance - max_distance_m) / max_distance_m
            score = -0.5 * excess_ratio  # Negative score

        return score

    def _score_time_limit(self, meter: CandidateMeter, query: UserQuery) -> float:
        """Score based on time limit flexibility - more buffer is better (0-1 scale, with penalty for insufficient)"""
        stay_minutes = self._get_stay_duration_minutes(query.preferences.stay_time)
        time_limit = meter.time_limit_minutes

        if time_limit >= stay_minutes * 1.5:
            # Generous buffer
            return 1.0
        elif time_limit >= stay_minutes:
            # Adequate buffer
            return 0.7
        else:
            # Insufficient time: penalty proportional to deficit
            deficit_ratio = (stay_minutes - time_limit) / stay_minutes
            return -1.0 * deficit_ratio  # Strong negative penalty

    def _calculate_total_cost(self, meter: CandidateMeter, stay_minutes: int) -> float:
        """Calculate estimated total parking cost"""
        avg_hourly_rate = sum(meter.rate_per_hour) / len(meter.rate_per_hour)
        hours = stay_minutes / 60
        return avg_hourly_rate * hours

    def _get_stay_duration_minutes(self, stay_time: StayTime) -> int:
        """Convert stay time preference to minutes (use max of range)"""
        return stay_time.value[1]

    def _get_max_budget(self, budget_range: BudgetRange) -> float:
        """Get maximum budget from range"""
        return budget_range.value[1]

    def _to_output_meter(
        self,
        meter: CandidateMeter,
        rank: int,
        route: dict,
        query: UserQuery
    ) -> OutputMeter:
        """Convert CandidateMeter to OutputMeter with ranking info"""
        stay_minutes = self._get_stay_duration_minutes(query.preferences.stay_time)

        return OutputMeter(
            spaceid=meter.spaceid,
            address=meter.address,
            rate_per_hour=sum(meter.rate_per_hour) / len(meter.rate_per_hour),
            time_limit_minutes=meter.time_limit_minutes,
            occupancy=meter.occupancy,
            latitude=meter.location.lat,
            longitude=meter.location.lon,
            distance_to_destination_meters=route["distance_meters"],
            walk_time_minutes=route["walk_time_minutes"],
            estimated_total_cost=self._calculate_total_cost(meter, stay_minutes),
            rank=rank
        )