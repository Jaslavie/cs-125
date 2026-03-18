import SwiftUI

// MARK: - Search Form View

/* Textual query inputs for intended destination and stay duration (similar to a navigation app).
 * currentLocation and currentTime are auto-captured in the ViewModel; this view collects targetLocation, budgetRangePreference, and stayTimePreference.
 *
 * Attributes:
 * - viewModel: ParkingViewModel; binds targetLocation, budgetRangePreference, stayTimePreference, and receives search/loading state.
 */
struct SearchFormView: View {
    @ObservedObject var viewModel: ParkingViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack { // Intended destination — free text, geocoded by backend; submit triggers search.
                Image(systemName: "mappin.circle.fill")  // Map pin icon.
                    .foregroundStyle(Theme.accent)
                TextField("Destination (e.g. Pantages Theatre)", text: $viewModel.targetLocation)  // Text field for destination.
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit { viewModel.searchParking() }  // Submit triggers search.
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 16) { // Selectors for max total cost (budget) and planned stay duration; prefilled with stored preferences; changes persist to session.
                Picker("Budget", selection: $viewModel.budgetRangePreference) { // Picker for budget range preference; prefilled with stored value.
                    ForEach(BudgetRangePreference.allCases, id: \.self) { budget in
                        Text(budget.displayName).tag(budget) // Display name for each budget range preference.
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.budgetRangePreference) { newValue in  // Persist budget change to session and log
                    viewModel.updateBudgetPreference(newValue)
                }

                Picker("Stay", selection: $viewModel.stayTimePreference) { // Picker for stay time preference; prefilled with stored value.
                    ForEach(StayTimePreference.allCases, id: \.self) { stay in
                        Text(stay.displayName).tag(stay) // Display name for each stay time preference.
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.stayTimePreference) { newValue in  // Persist stay duration change to session and log
                    viewModel.updateStayDurationPreference(newValue)
                }
            } 

            Button(action: { viewModel.searchParking() }) { // Button to trigger search.
                HStack {
                    if case .loading = viewModel.uiState { // Progress view when loading.
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Begin Journey") // Text for button.
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(viewModel.targetLocation.trimmingCharacters(in: .whitespaces).isEmpty || (viewModel.uiState == .loading))  // Disabled when destination empty or already loading; submits query and shows ranked list.
        }
        .padding()
    }
}

/* Budget category labels for UI: low $0–$10, medium $10–$20, high $20–$50.
 *
 * Attributes:
 * - cases low, medium, high; displayName returns user-facing string with dollar range.
 */
extension BudgetRangePreference {
    var displayName: String { // User-facing string with dollar range.
        switch self {
        case .low: return "Low ($0–$10)"
        case .medium: return "Medium ($10–$20)"
        case .high: return "High ($20–$50)"
        }
    }
}

/* Stay duration labels: short ≤1 hr, medium 1–2 hr, long 2–4 hr.
 *
 * Attributes:
 * - cases short, medium, long; displayName returns user-facing string with time range.
 */
extension StayTimePreference {
    var displayName: String { // User-facing string with time range.
        switch self {
        case .short: return "Short (≤1 hr)"
        case .medium: return "Medium (1–2 hr)"
        case .long: return "Long (2–4 hr)"
        }
    }
}
