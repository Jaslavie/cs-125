const { rankParkingSpots } = require("../src/ranking/ranking");

console.log("test running...");

const destination = { lat: 34.100, lng: -118.324 };

const spots = [
  {
    spaceid: "CLOSE",
    latlng: { lat: 34.1005, lng: -118.324 },
    rate: 3,
    timelimit: 120,
  },
  {
    spaceid: "FAR",
    latlng: { lat: 34.110, lng: -118.335 },
    rate: 1,
    timelimit: 240,
  },
];

const result = rankParkingSpots(spots, destination, {
  budgetRangePreference: "medium",
  walkingDistancePreference: "close",
  stayTimePreference: "medium",
});

console.table(
  result.map((r: any) => ({
    id: r.spaceid,
    score: r.score.toFixed(3),
    walkTime: r.walkTime,
    cost: r.estimatedTotalCost.toFixed(2),
    rank: r.rank,
  }))
);

if (result[0].spaceid !== "CLOSE") {
  throw new Error(" Test failed: CLOSE should rank first");
}

console.log("Test passed!");
