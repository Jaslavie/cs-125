import SwiftUI

struct SpotCardView: View {
    let spot: ScoredSpot
    
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
            }
            
            Text(spot.meterAddress)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            
            HStack(spacing: 16) {
                Label("\(spot.walkTime) min walk", systemImage: "figure.walk")
                Label("$\(String(format: "%.2f", spot.rate))/hr", systemImage: "dollarsign.circle")
                Label("\(spot.timelimit) min limit", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(Theme.secondaryText)
            
            Text("Est. total: $\(String(format: "%.2f", spot.estimatedTotalCost))")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(spot.colorCode.color, lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Theme.cardShadow, radius: 4, x: 0, y: 2)
    }
}
