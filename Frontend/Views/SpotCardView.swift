import SwiftUI

// MARK: - Spot Card View

/*
 * One card in the ranked list: shows spot id, rank, address, walk time, hourly rate, time limit,
 * occupancy status, and estimated total cost. Cards are color-coded by recommendation strength
 * (green = highly recommended, yellow = good, orange = acceptable).
 *
 * When a spot is selected the border switches to the accent color and thickens.
 * When a spot is occupied the background dims to gray and the border turns gray to indicate unavailability.
 * Tapping anywhere on the card invokes onTap so the caller can update selection state.
 *
 * Attributes:
 * - spot: ScoredSpot; supplies spaceid, rank, meterAddress, walkTime, rate, timelimit, estimatedTotalCost, colorCode, and baseline occupancy information about the associated parking spot.
 * - isSelected: When true, renders the accent-color selected highlight on the card border.
 * - liveOccupancy: Live-polled occupancy string for this spot ("VACANT" / "OCCUPIED" / "UNKNOWN");
 *   overrides spot.occupancy when non-nil.
 * - onTap: Closure called when the user taps the card; the caller handles selection toggle logic.
 * - effectiveOccupancy: Computed; uses liveOccupancy if available, otherwise falls back to spot.occupancy. This provides a fallback in case no live polling is able to take place.
 * - isOccupied: Computed; true when effectiveOccupancy equals "OCCUPIED".
 */
struct SpotCardView: View {
    let spot: ScoredSpot  // The spot to display.
    let isSelected: Bool  // Whether this card is the currently selected spot.
    let liveOccupancy: String?  // Latest polled occupancy; overrides spot.occupancy when non-nil.
    let onTap: () -> Void  // Called when the user taps the card.

    /*
     * Computed property that resolves the occupancy string to display.
     * Prefers the live-polled value; falls back to the value returned by the ranking backend.
     * This provides a fallback in case no live polling is able to take place.
     *
     * Returns: The most current occupancy string available for this spot.
     */
    private var effectiveOccupancy: String {
        liveOccupancy ?? spot.occupancy
    }

    /*
     * Computed property that indicates whether the spot is currently occupied.
     *
     * Returns: True when effectiveOccupancy equals "OCCUPIED".
     */
    private var isOccupied: Bool {
        effectiveOccupancy == "OCCUPIED"
    }

    /*
     * Computed property that maps the raw occupancy string to a user-facing display label.
     * "UNKNOWN" is remapped to "NO OCCUPANCY DATA" to clearly communicate that the absence of
     * status information is a LADOT sensor coverage gap, not an app error.
     *
     * Returns: Display string for the occupancy badge.
     */
    private var occupancyLabel: String {
        effectiveOccupancy == "UNKNOWN" ? "NO OCCUPANCY DATA" : effectiveOccupancy
    }

    /*
     * Computed property that returns the foreground color for the occupancy badge.
     * OCCUPIED → red; VACANT → green; UNKNOWN (no sensor data) → secondary gray.
     *
     * Returns: SwiftUI Color for the occupancy label.
     */
    private var occupancyLabelColor: Color {
        switch effectiveOccupancy {
        case "OCCUPIED": return .red
        case "VACANT":   return .green
        default:         return Theme.secondaryText  // UNKNOWN — neutral; no sensor data available.
        }
    }

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
                Label("Roughly estimated walktime: \(spot.walkTime) min walk", systemImage: "figure.walk")
                Label("$\(String(format: "%.2f", spot.rate))/hr", systemImage: "dollarsign.circle")
                Label("\(spot.timelimit) min limit", systemImage: "clock")
                Text(occupancyLabel)  // Live occupancy badge; green for VACANT, red for OCCUPIED, gray for no sensor data.
                    .fontWeight(.semibold)
                    .foregroundStyle(occupancyLabelColor)
            }
            .font(.caption)
            .foregroundStyle(Theme.secondaryText)  // Walk time (min), hourly rate, time limit (min), occupancy status.

            Text("Est. total: $\(String(format: "%.2f", spot.estimatedTotalCost))")
                .font(.subheadline)
                .fontWeight(.medium)  // Projected total expense for the user's stay.
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isOccupied ? Color.gray.opacity(0.3) : Theme.cardBackground)  // Gray background when occupied to signal unavailability.
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Theme.accent : (isOccupied ? Color.gray : spot.colorCode.color),
                    lineWidth: isSelected ? 4 : 3
                )  // Accent border when selected; gray border when occupied; colorCode border otherwise.
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.cardShadow, radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()  // Delegate selection toggle to the parent (ResultsListView / viewModel).
        }
    }
}
