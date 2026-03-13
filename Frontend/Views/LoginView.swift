import SwiftUI

// MARK: - Login View
/*
 * Entry screen shown on app launch. Presents fields for username and password so the user can
 * authenticate against locally stored credentials. Successful login sets SessionManager.currentUsername,
 * which causes ContentView to transition into the main parking experience.
 *
 * Attributes:
 * - sessionManager: Shared SessionManager instance; validates credentials and manages active user.
 */
struct LoginView: View {
    @ObservedObject var sessionManager: SessionManager

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) { // Login title and description.
                Text("PetrParker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Sign in to access your saved preferences and start a new journey.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) { // Username and password fields.
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onSubmit { attemptLogin() }
            }
            .padding(.horizontal)

            if let message = errorMessage { // Error message.
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: attemptLogin) { // Login button.
                Text("Login")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
            .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)

            NavigationLink { // Create account button.
                CreateAccountView(sessionManager: sessionManager)
            } label: {
                Text("Create Account")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.top, 8)

            Spacer() // Spacer to push content to the top of the screen.
        }
    }

    /*
     * Attempts to log in with the provided username and password.
     * If successful, sets the current username and loads the user's preferences.
     * If unsuccessful, sets the error message according to the specific error
     * that occurred.
     */
    private func attemptLogin() {
        errorMessage = nil 
        do {
            try sessionManager.login(username: username, password: password) // On success, ContentView will observe currentUsername and transition automatically.
        } catch SessionManager.SessionError.usernameNotFound { // If the username is not found, set the error message to "No account found for that username."
            errorMessage = "No account found for that username."
        } catch SessionManager.SessionError.incorrectPassword { // If the password is incorrect, set the error message to "Incorrect password. Please try again."
            errorMessage = "Incorrect password. Please try again."
        } catch SessionManager.SessionError.invalidInput { // If the input is invalid, set the error message to "Please enter both a username and password."
            errorMessage = "Please enter both a username and password."
        } catch { // If an unknown error occurs, set the error message to "Unable to log in. Please try again."
            errorMessage = "Unable to log in. Please try again."
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(sessionManager: .shared)
    }
}

