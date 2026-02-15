import SwiftUI

// MARK: - Content View

/*
 * Main layout: input widgets for destination and duration at top, interactive map in the center,
 * and a side panel that displays the ranked list. Uber-style: search form, map, then scrollable results cards.
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
                .frame(height: 280)  // Fixed height keeps map visible above the list; each spot shown as a pin.

            Divider()

            ResultsListView(viewModel: viewModel)
                .frame(maxHeight: .infinity)  // Side panel: ranked list as scrollable cards; states initial/loading/results/no results/error.
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}
