import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ParkingViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            SearchFormView(viewModel: viewModel)
                .disabled(viewModel.uiState == .loading)
            
            Divider()
            
            MapView(viewModel: viewModel)
                .frame(height: 280)
            
            Divider()
            
            ResultsListView(viewModel: viewModel)
                .frame(maxHeight: .infinity)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ContentView()
}
