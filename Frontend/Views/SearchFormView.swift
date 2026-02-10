import SwiftUI

struct SearchFormView: View {
    @ObservedObject var viewModel: ParkingViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Theme.accent)
                TextField("Destination (e.g. Pantages Theatre)", text: $viewModel.targetLocation)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit { viewModel.searchParking() }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            HStack(spacing: 16) {
                Picker("Budget", selection: $viewModel.budgetRangePreference) {
                    ForEach(BudgetRangePreference.allCases, id: \.self) { budget in
                        Text(budget.displayName).tag(budget)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Stay", selection: $viewModel.stayTimePreference) {
                    ForEach(StayTimePreference.allCases, id: \.self) { stay in
                        Text(stay.displayName).tag(stay)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Button(action: { viewModel.searchParking() }) {
                HStack {
                    if case .loading = viewModel.uiState {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Find Parking")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(viewModel.targetLocation.trimmingCharacters(in: .whitespaces).isEmpty || (viewModel.uiState == .loading))
        }
        .padding()
    }
}

extension BudgetRangePreference {
    var displayName: String {
        switch self {
        case .low: return "Low ($0–$10)"
        case .medium: return "Medium ($10–$20)"
        case .high: return "High ($20–$50)"
        }
    }
}

extension StayTimePreference {
    var displayName: String {
        switch self {
        case .short: return "Short (≤1 hr)"
        case .medium: return "Medium (1–2 hr)"
        case .long: return "Long (2–4 hr)"
        }
    }
}
