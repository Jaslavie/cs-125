import SwiftUI
import MapKit

// CLLocationCoordinate2D is a C struct that does not synthesize Equatable; the conformance is
// required so SwiftUI's onChange(of:) can differentiate between successive GPS fixes.
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
 * The route itself is calculated in ParkingViewModel.calculateRoute(to:) via MKDirections;
 * MapView only renders the resulting MKRoute stored in viewModel.selectedRoute.
 * The camera auto-centers on the user's position the first time a GPS fix is received;
 * subsequent panning is left to the user. When new search results arrive the camera zooms to a
 * bounding region that fits all ranked pins so no spot is out of frame.
 *
 * Attributes:
 * - viewModel: ParkingViewModel; provides rankedResults for pins, selectedRoute for the polyline,
 *   and currentLocation to trigger the initial camera re-center.
 * - position: Local camera state initialised to Downtown LA; updated on first GPS fix and on
 *   each new set of search results.
 * - hasCenteredOnUser: Guard flag that prevents repeated GPS-triggered camera jumps after the
 *   first GPS lock.
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

            if let spots = viewModel.rankedResults?.spots {  // Each spot shown as annotation if ranked results exist; pins use coordinate and colorCode for recommendation strength.
                ForEach(spots) { spot in
                    Annotation(spot.spaceid, coordinate: spot.coordinate, anchor: .bottom) {
                        MeterPinView(spot: spot)
                    }
                }
            }

            if let route = viewModel.selectedRoute {  // Renders the MKRoute computed by ParkingViewModel.calculateRoute(to:) as a blue driving-route polyline.
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
        .onChange(of: viewModel.rankedResults) { _, newResults in
            // When a new set of ranked results arrives, zoom the camera to a bounding region
            // that fits all pins so no spot is out of frame regardless of where the user is.
            guard let spots = newResults?.spots, !spots.isEmpty else { return }
            let coords = spots.map { $0.coordinate }
            let lats = coords.map { $0.latitude }
            let lons = coords.map { $0.longitude }
            let minLat = lats.min()!, maxLat = lats.max()!
            let minLon = lons.min()!, maxLon = lons.max()!
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            )
            // 1.5× padding factor ensures pins are not clipped at the edges of the frame.
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.5, 0.01),
                longitudeDelta: max((maxLon - minLon) * 1.5, 0.01)
            )
            position = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}
