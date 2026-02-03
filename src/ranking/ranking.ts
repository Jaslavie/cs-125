/**
 * Ranking logic
 *
 * ASSUMES VALID input ;; does not fetch data
 * 
 * MINDFUL: location, budget, time; 
 */


// location
export type LatLng = {
  lat: number;
  lng: number;
};


export type UserPreferences = {
  budgetRangePreference: "low" | "medium" | "high";
  walkingDistancePreference: "close" | "medium" | "far";
  stayTimePreference: "short" | "medium" | "long";
};

export type ParkingSpot = { // parking spot == candidate meter in data layer
  spaceid: string;
  latlng: LatLng;
  rate: number;        // $ per hour from raterange 
  timelimit: number;   // minutes from 2hr
};

export type RankedParkingSpot = ParkingSpot & { // ranked parking spot == ranked meter in data layer
  distanceToDestination: number; // in meters
  walkTime: number;              // in minutes
  estimatedTotalCost: number;    // cost 
  score: number;
  rank: number;
};


// helper functions 
/**
 * this will compute distance between two lat/lng points in meters -- aka haversine
 */
function distanceMeters(a: LatLng, b: LatLng): number {
    const R = 6371000;
    const toRad = (d: number) => (d * Math.PI) / 180;

    const dLat = toRad(b.lat - a.lat);
    const dLng = toRad(b.lng - a.lng);
    const lat1 = toRad(a.lat);
    const lat2 = toRad(b.lat);

    const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;

  return 2 * R * Math.asin(Math.sqrt(h));
}

/**
 * this converts user preferences into scoring weights.
 */
function getWeights(prefs: UserPreferences) {
  return {
    distance: prefs.walkingDistancePreference === "close" ? 0.45 : 0.3,
    cost: prefs.budgetRangePreference === "low" ? 0.45 : 0.3,
    time: prefs.stayTimePreference === "long" ? 0.25 : 0.2,
  };
}


// main logic: //
/**
 * Rank candidate parking spots based on context-aware scoring.
 */
export function rankParkingSpots(
  candidates: ParkingSpot[],
  destination: LatLng,
  userPrefs: UserPreferences
): RankedParkingSpot[] {

  const weights = getWeights(userPrefs);

  // init bounds
  const MAX_DISTANCE = 1000;
  const MAX_COST = 20;   
  const IDEAL_TIME = 180; 
  
  const scored = candidates.map((spot) => {
  const distance = distanceMeters(spot.latlng, destination);
  const walkTime = Math.ceil(distance / 80); // avg 80 m/min
  const estimatedTotalCost = spot.rate * (spot.timelimit / 60);

  // TODO: normalize distance, cost, and time scores from 0 to 1
  const distanceScore = 1 - Math.min(distance / MAX_DISTANCE, 1);
  const costScore = 1- Math.min(estimatedTotalCost / MAX_COST, 1);
  const timeScore = Math.min(spot.timelimit / IDEAL_TIME, 1);

  const score =
    weights.distance * distanceScore +
    weights.cost * costScore +
    weights.time * timeScore;

  return {
    ...spot,
    distanceToDestination: distance,
    walkTime,
    estimatedTotalCost,
    score,
    rank: -1, // marked after sorting
  };
  });


  // sorts by score
  scored.sort((a, b) => b.score - a.score);

  // assign ranks and return top K rankings
  return scored.slice(0, 8).map((spot, index) => ({
    ...spot,
    rank: index + 1,
  }));
}
