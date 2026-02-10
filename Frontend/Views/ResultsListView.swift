import SwiftUI

struct ResultsListView: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        Group {
            switch viewModel.uiState {
            case .initial:
                emptyState
            case .loading:
                loadingState
            case .results(let results):
                resultsState(results)
            case .noResults:
                noResultsState
            case .error(let message):
                errorState(message)
            }
        }
    }
    
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
    
    private func resultsState(_ results: RankedResults) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(results.spots) { spot in
                    SpotCardView(spot: spot)
                }
            }
            .padding(.horizontal)
        }
    }
    
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
