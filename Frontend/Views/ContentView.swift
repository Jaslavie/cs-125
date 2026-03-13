import SwiftUI

// MARK: - Content View

/*
 * Root shell for the app. Wraps the authentication flow and the main parking experience in a
 * NavigationStack. When no user is logged in, shows LoginView (with a link to CreateAccountView);
 * when a user is logged in, shows MainParkingView with the full search/map/results journey UI.
 */
struct ContentView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var parkingViewModel = ParkingViewModel()

    var body: some View {
        NavigationStack {
            if sessionManager.currentUsername == nil {
                LoginView(sessionManager: sessionManager)
            } else {
                MainParkingView(sessionManager: sessionManager, viewModel: parkingViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
