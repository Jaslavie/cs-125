import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    private let laRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    
    var body: some View {
        Map(position: .constant(.region(laRegion))) {
            if let spots = viewModel.rankedResults?.spots {
                ForEach(spots) { spot in
                    Annotation(spot.spaceid, coordinate: spot.coordinate, anchor: .bottom) {
                        MeterPinView(spot: spot)
                    }
                }
            }
        }
        .mapStyle(.standard)
        .allowsHitTesting(true)
    }
}
