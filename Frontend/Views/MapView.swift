import SwiftUI
import MapKit

// MARK: - Map View

/*
 * Interactive map; each parking spot is shown as a pin. Project scope is a specific area 
 * (e.g. Downtown LA); map is centered there. Pins appear only when there are results; 
 initial/loading/no results/error show an empty map.
 *
 * Attributes:
 * - viewModel: ParkingViewModel; provides rankedResults for pins and map context.
 * - laRegion: Default region centered on Downtown LA (project geographic scope).
 */
struct MapView: View {
    @ObservedObject var viewModel: ParkingViewModel

    private let laRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    var body: some View {
        Map(position: .constant(.region(laRegion))) {
            if let spots = viewModel.rankedResults?.spots {  // Each spot shown as annotation; pins use coordinate and colorCode for recommendation strength.
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
