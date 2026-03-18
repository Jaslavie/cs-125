import SwiftUI

// MARK: - Main Parking View
/*
 * Hosts the primary parking experience once a user is logged in: search form, map, and results list,
 * along with the occupied-spot alert. Also provides a Logout button that clears the active session and
 * returns the app to the login screen via ContentView's NavigationStack.
 *
 * Attributes:
 * - sessionManager: Shared SessionManager; used here to trigger logout.
 * - viewModel: ParkingViewModel; single source of truth for search flow and real-time journey state.
 */
struct MainParkingView: View {
    @ObservedObject var sessionManager: SessionManager
    @StateObject var viewModel: ParkingViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LA Parking")
                    .foregroundStyle(.primary)
                    .font(.headline)
                Spacer()
                Button("Logout") { // Logout button; end journey and clear session so user returns to login screen.
                    viewModel.resetToInitial()
                    sessionManager.logout()
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            SearchFormView(viewModel: viewModel) // Search form view.
                .disabled(viewModel.uiState == .loading) // Disable the search form while loading.

            Divider()

            MapView(viewModel: viewModel) // Map view.
                .frame(height: 280)

            Divider()

            ResultsListView(viewModel: viewModel) // Results list view.
                .frame(maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .alert("Spot is Now Occupied", isPresented: $viewModel.showSpotOccupiedAlert) { // Occupied-spot alert.
            if viewModel.hasAnyVacantRankedSpots {
                Button("Select Next Best") { // Select next best button.
                    viewModel.selectNextBestUnoccupiedSpot()
                }
            }
            Button("Find More Parking") { // Find more parking button.
                viewModel.searchParking(preserveHistory: true)
            }
            Button("Dismiss", role: .cancel) {} // Dismiss button.  
        } message: {
            Text("The parking spot you selected has just been taken. Please choose an action.")
        }
    }
}

#Preview {
    MainParkingView(sessionManager: .shared, viewModel: ParkingViewModel())
}

