import SwiftUI

// MARK: - Content View

/*
 * Main layout: input widgets for destination and duration at top, interactive map in the center,
 * and a bottom panel that displays the ranked list. Uber-style: search form, map, then scrollable results cards.
 * Hosts the occupied-spot alert so it can present over the full screen from a single, stable anchor.
 *
 * Attributes:
 * - viewModel: Single source of truth for search flow; user inputs and auto-captured context feed the recommendation engine.
 */
struct ContentView: View {
    @StateObject private var viewModel = ParkingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            SearchFormView(viewModel: viewModel)
                .disabled(viewModel.uiState == .loading)  // Disabled while loading so user cannot submit twice.

            Divider()

            MapView(viewModel: viewModel)
                .frame(height: 280)  // Fixed height keeps map visible above the list; each spot shown as a pin with user location shown as a blue dot.

            Divider()

            ResultsListView(viewModel: viewModel)
                .frame(maxHeight: .infinity)  // Bottom panel: ranked list as scrollable cards; states initial/loading/results/no results/error/journeyComplete.
        }
        .background(Color(.systemGroupedBackground))
        .alert("Spot is Now Occupied", isPresented: $viewModel.showSpotOccupiedAlert) {
            // "Select Next Best" is offered only when at least one other ranked spot is still vacant.
            if viewModel.hasAnyVacantRankedSpots {
                Button("Select Next Best") {
                    viewModel.selectNextBestUnoccupiedSpot()
                }
            }
            Button("Find More Parking") { // Re-ranks while preserving the full journey history and original start time.
                viewModel.searchParking(preserveHistory: true)
            }
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text("The parking spot you selected has just been taken. Please choose an action.")
        }
    }
}

#Preview {
    ContentView()
}
