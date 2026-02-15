import SwiftUI

// MARK: - Results List View

/* Side panel that displays the ranked list as scrollable cards. Each UI state maps to a different panel: initial (prompt), loading (progress), results (cards), no results (message + expand suggestion), error (alert with retry).
 *
 * Attributes:
 * - viewModel: ParkingViewModel; provides uiState and rankedResults; drives emptyState, loadingState, resultsState, noResultsState, errorState.
 */
struct ResultsListView: View {
    @ObservedObject var viewModel: ParkingViewModel

    var body: some View {
        Group {  // Switches on the UI state to display the appropriate panel.
            switch viewModel.uiState {
            case .initial:
                emptyState  // Initial state: results panel shows empty-state prompt (e.g. enter destination and tap Find Parking).
            case .loading:
                loadingState  // Loading state: progress indicator and message on results panel.
            case .results(let results):
                resultsState(results)  // Results state: map shows pins; results panel shows ranked set of spots as scrollable cards.
            case .noResults:
                noResultsState  // No-results state: message and suggestion to expand radius, with retry.
            case .error(let message):
                errorState(message)  // Error state: message and retry option.
            }
        }
    }

    /* Initial state: results panel shows empty-state prompt (e.g. enter destination and tap Find Parking).
     *
     * Returns a View.
     */
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "map.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.secondaryText)
            Text("Enter a destination and tap Find Parking")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    /* Loading state: progress indicator and message on results panel.
     *
     * Returns a View.
     */
    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Searching for spots...")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    /* Results state: map shows pins; results panel shows ranked set of spots as scrollable cards.
     *
     * Parameters:
     * - results: RankedResults containing spots to display as SpotCardView cards.
     *
     * Returns a View.
     */
    private func resultsState(_ results: RankedResults) -> some View {
        ScrollView {  // Scrollable list of spots.
            LazyVStack(spacing: 12) {
                ForEach(results.spots) { spot in
                    SpotCardView(spot: spot)  // Each spot displayed as a card in the results panel.
                }
            }
            .padding(.horizontal)  // Padding for horizontal scrolling.
        }
    }

    /* No-results state: message and suggestion to expand radius, with retry button.
     *
     * Returns a View.
     */
    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "parkingsign.circle")
                .font(.system(size: 44))
                .foregroundStyle(Theme.secondaryText)
            Text("No spots found")
                .font(.headline)
            Text("Try expanding your search radius or adjusting your preferences.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    /* Error state: message and retry option.
     *
     * Parameters:
     * - message: Error message string to display.
     *
     * Returns a View.
     */
    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
