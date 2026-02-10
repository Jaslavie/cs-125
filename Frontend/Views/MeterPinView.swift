import SwiftUI
import MapKit

struct MeterPinView: View {
    let spot: ScoredSpot
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(spot.colorCode.color)
            Text(spot.spaceid)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}
