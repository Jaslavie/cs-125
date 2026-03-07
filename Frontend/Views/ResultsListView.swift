import SwiftUI

// MARK: - Results List View

/* Side panel that displays the ranked list as scrollable cards, or a journey summary when the journey ends.
 * Each UI state maps to a different panel: initial (prompt), loading (progress), results (cards + End Journey button),
 * no results (message + expand suggestion), error (alert with retry), journeyComplete (summary screen).
 *
 * Attributes:
 * - viewModel: ParkingViewModel; provides uiState, rankedResults, selectedSpotID, liveOccupancy,
 *   and actions (selectSpot, deselectSpot, endJourney, resetToInitial, retry).
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
            case .journeyComplete(let summary):
                journeyCompleteState(summary)  // Journey complete state: summary of the full parking journey.
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

    /* Results state: map shows pins; results panel shows ranked set of spots as scrollable cards
     * with an "End Journey" button at the top to terminate the active query session.
     * When mock mode is active, a collapsible debug panel is shown above the cards to allow
     * manual control of per-spot occupancy states for testing.
     *
     * Parameters:
     * - results: RankedResults containing spots to display as SpotCardView cards.
     *
     * Returns a View.
     */
    private func resultsState(_ results: RankedResults) -> some View {
        VStack(spacing: 0) {
            Button("End Journey") {
                viewModel.endJourney()
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding([.horizontal, .top])
            .frame(maxWidth: .infinity, alignment: .trailing)  // End Journey button; stops polling and transitions to journeyCompleteState.

            if APIClient.shared.useMockMode {
                mockDebugPanel(results)  // Debug panel; only visible in mock mode for testing occupancy transitions.
            }

            ScrollView {  // Scrollable list of spots.
                LazyVStack(spacing: 12) {
                    ForEach(results.spots) { spot in
                        SpotCardView(
                            spot: spot,
                            isSelected: viewModel.selectedSpotID == spot.spaceid,
                            liveOccupancy: viewModel.liveOccupancy[spot.spaceid],
                            onTap: {
                                if viewModel.selectedSpotID == spot.spaceid {
                                    viewModel.deselectSpot()  // Tapping the selected card again deselects it.
                                } else {
                                    viewModel.selectSpot(spot)  // Tapping a new card selects it and recalculates the route.
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }

    /* Mock occupancy debug panel; only rendered when APIClient.shared.useMockMode is true.
     * Displays a 3-way segmented picker (VACANT / OCCUPIED / UNKNOWN) for each ranked spot so
     * every occupancy transition scenario can be triggered manually without waiting for live data.
     * Resetting all spots to VACANT is available via the "Reset All" button.
     *
     * Scenarios this panel enables:
     *  - Set selected spot → OCCUPIED while others remain VACANT/UNKNOWN: alert fires with "Select Next Best"
     *  - Set an unselected spot → OCCUPIED: that card grays out, no alert
     *  - Set all spots → OCCUPIED: alert fires with only "Find New Spots"
     *  - Set an OCCUPIED unselected spot → VACANT or UNKNOWN: card color restores
     *
     * Parameters:
     * - results: RankedResults whose spots drive the per-spot picker rows.
     *
     * Returns a View.
     */
    private func mockDebugPanel(_ results: RankedResults) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                Text("Mock Occupancy Controls")
                    .fontWeight(.semibold)
                Spacer()
                Button("Reset All") {
                    for spot in results.spots {
                        APIClient.shared.mockOccupancyOverrides.removeValue(forKey: spot.spaceid)
                    }
                    viewModel.triggerMockOccupancyRefresh()
                }
                .font(.caption)
                .tint(.orange)
            }
            .font(.caption)
            .foregroundStyle(.orange)

            ScrollView {  // Scrollable so all spots are reachable without expanding the panel height.
                VStack(spacing: 4) {
                    ForEach(results.spots) { spot in
                        HStack(spacing: 6) {
                            Text("#\(spot.rank) \(spot.spaceid)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .frame(width: 76, alignment: .leading)
                            Picker("", selection: mockOccupancyBinding(for: spot.spaceid)) {
                                Text("VACANT").tag("VACANT")
                                Text("OCCUPIED").tag("OCCUPIED")
                                Text("UNKNOWN").tag("UNKNOWN")
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                }
            }
            .frame(height: 60)  // ~25% of the original full-height panel; tall enough for ~2 rows, scrollable for the rest.
        }
        .padding(8)
        .background(Color.orange.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 6)
    }

    /* Creates a two-way binding for a single spot's mock occupancy override.
     * Reading returns the current override value, defaulting to "VACANT" if none is set.
     * Writing saves the new value into APIClient.shared.mockOccupancyOverrides and immediately
     * triggers an occupancy refresh so the card UI updates without waiting for the next poll tick.
     *
     * Parameters:
     * - spaceid: The parking meter space ID whose override binding is needed.
     *
     * Returns: A Binding<String> wired to APIClient.shared.mockOccupancyOverrides[spaceid].
     */
    private func mockOccupancyBinding(for spaceid: String) -> Binding<String> {
        Binding(
            get: { APIClient.shared.mockOccupancyOverrides[spaceid] ?? "VACANT" },
            set: { newValue in
                APIClient.shared.mockOccupancyOverrides[spaceid] = newValue
                viewModel.triggerMockOccupancyRefresh()  // Apply immediately without waiting for the 7-second poll tick.
            }
        )
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

    /* Journey complete state: shown after the user taps "End Journey". Displays a summary of all
     * spots chosen during the session in chronological order, a full card for the final destination,
     * the total journey duration, and a button to start a new search.
     *
     * Parameters:
     * - summary: JourneySummary containing the ordered spot history, final spot, and elapsed time.
     *
     * Returns a View.
     */
    private func journeyCompleteState(_ summary: JourneySummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Journey Complete")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Journey time: \(summary.durationMinutes) min")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .padding(.top, 8)

                Divider()

                // Chronological spot history
                if !summary.chosenSpots.isEmpty {
                    Text("Spots Visited")
                        .font(.headline)
                    LazyVStack(spacing: 8) {
                        ForEach(Array(summary.chosenSpots.enumerated()), id: \.offset) { index, spot in
                            HStack(spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Theme.primaryInverse)
                                    .frame(width: 22, height: 22)
                                    .background(Theme.accent)
                                    .clipShape(Circle())  // Numbered badge for chronological order.
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Meter \(spot.spaceid)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(spot.meterAddress)
                                        .font(.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                Spacer()
                                Text("Rank #\(spot.rank)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    Divider()
                }

                // Final destination card
                if let finalSpot = summary.finalSpot {
                    Text("Final Destination")
                        .font(.headline)
                    SpotCardView(
                        spot: finalSpot,
                        isSelected: false,
                        liveOccupancy: nil,
                        onTap: {}
                    )  // Read-only card; no interaction in summary view.
                }

                // Start new journey
                Button("Start New Journey") {
                    viewModel.resetToInitial()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
        }
    }
}
