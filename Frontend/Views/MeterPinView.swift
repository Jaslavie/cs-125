import SwiftUI
import MapKit

// MARK: - Meter Pin View

/*
 * Map annotation for a single parking spot: shows spaceid (e.g. "HO108") and color by recommendation strength (green / yellow / orange).
 *
 * Attributes:
 * - spot: ScoredSpot; supplies spaceid and colorCode for pin label and tint.
 */
struct MeterPinView: View {
    let spot: ScoredSpot

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(spot.colorCode.color)  // Tinted with the spot's color code.
            Text(spot.spaceid)
                .font(.caption2)
                .fontWeight(.medium)  // Spaceid label.
        }
    }
}
