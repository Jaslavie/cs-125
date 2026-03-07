import SwiftUI
import MapKit

// CLLocationCoordinate2D is a C struct that does not synthesize Equatable; the conformance is
// required here so SwiftUI's onChange(of:) can diff successive GPS fixes.
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Map View

/*
 * Interactive map; the user's live location is shown as a blue dot (UserAnnotation) at all times.
 * When results exist, each parking spot is rendered as a MeterPinView annotation.
 * When a spot is selected, a blue polyline traces the driving route from the user to that spot.
 * The camera auto-centers on the user's position the first time a GPS fix is received;
 * subsequent panning is left to the user.
 *
 * Attributes:
 * - viewModel: ParkingViewModel; provides rankedResults for pins, selectedRoute for the polyline,
 *   and currentLocation to trigger the initial camera re-center.
 * - position: Local camera state initialised to Downtown LA; updated once on first GPS fix.
 * - hasCenteredOnUser: Guard flag that prevents repeated camera jumps after the first GPS lock.
 */
struct MapView: View {
    @ObservedObject var viewModel: ParkingViewModel

    private let laRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    )  // Camera position; initialised to LA center, snaps to user on first GPS fix.
    @State private var hasCenteredOnUser = false  // Prevents repeated camera jumps after the first GPS lock.

    var body: some View {
        Map(position: $position) {
            UserAnnotation()  // Blue dot showing the user's real-time GPS position.

            if let spots = viewModel.rankedResults?.spots {  // Each spot shown as annotation; pins use coordinate and colorCode for recommendation strength.
                ForEach(spots) { spot in
                    Annotation(spot.spaceid, coordinate: spot.coordinate, anchor: .bottom) {
                        MeterPinView(spot: spot)
                    }
                }
            }

            if let route = viewModel.selectedRoute {  // Blue polyline tracing the driving route to the selected spot.
                MapPolyline(route)
                    .stroke(.blue, lineWidth: 4)
            }
        }
        .mapStyle(.standard)
        .allowsHitTesting(true)
        .onChange(of: viewModel.currentLocation) { _, newLocation in
            // Re-center the camera once on the first GPS fix so the user sees their position.
            if !hasCenteredOnUser, let coord = newLocation {
                position = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                ))
                hasCenteredOnUser = true
            }
        }
    }
}
