import SwiftUI

// MARK: - Spot Card View

/*
 * One card in the ranked list: shows spot id, rank, address, walk time, hourly rate, time limit, and estimated total cost. Cards are color-coded by recommendation strength (green highly recommended, yellow good, orange acceptable).
 *
 * Attributes:
 * - spot: ScoredSpot; supplies spaceid, rank, meterAddress, walkTime, rate, timelimit, estimatedTotalCost, colorCode.
 */
struct SpotCardView: View {
    let spot: ScoredSpot  // The spot to display.

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Meter \(spot.spaceid)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("#\(spot.rank)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }  // Spot identifier (e.g. "HO108") and rank (position in list).

            Text(spot.meterAddress)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)  // Street address of the meter (e.g. "6233 Hollywood Blvd").

            HStack(spacing: 16) {
                Label("\(spot.walkTime) min walk", systemImage: "figure.walk")
                Label("$\(String(format: "%.2f", spot.rate))/hr", systemImage: "dollarsign.circle")
                Label("\(spot.timelimit) min limit", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(Theme.secondaryText)  // Walk time (min), hourly rate, time limit; position, walk duration, fee per hour, pertinent cautions.

            Text("Est. total: $\(String(format: "%.2f", spot.estimatedTotalCost))")
                .font(.subheadline)
                .fontWeight(.medium)  // Projected total expense for the user's stay.
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(spot.colorCode.color, lineWidth: 3)  // Border color reflects recommendation strength (green / yellow / orange).
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.cardShadow, radius: 4, x: 0, y: 2)
    }
}
