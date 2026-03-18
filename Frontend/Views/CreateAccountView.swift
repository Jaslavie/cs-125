import SwiftUI

// MARK: - Create Account View
/*
 * Screen for creating a new account. Collects username, password, and initial budget/stay
 * preferences. On success, sets the new user as the active session and exits this view,
 * transitioning to the main parking experience.
 *
 * Attributes:
 * - sessionManager: Shared SessionManager instance; creates and persists new user accounts.
 */
struct CreateAccountView: View {
    @ObservedObject var sessionManager: SessionManager

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var budget: BudgetRangePreference = .medium
    @State private var stay: StayTimePreference = .medium
    @State private var errorMessage: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                TextField("Username", text: $username) // Username field.
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password) // Password field.
                    .textContentType(.newPassword)
            }

            Section(header: Text("Preferences")) {
                Picker("Budget", selection: $budget) { // Budget picker.
                    ForEach(BudgetRangePreference.allCases, id: \.self) { value in
                        Text(value.displayName).tag(value)
                    }
                }

                Picker("Stay Duration", selection: $stay) { // Stay duration picker.
                    ForEach(StayTimePreference.allCases, id: \.self) { value in
                        Text(value.displayName).tag(value)
                    }
                }
            }

            if let message = errorMessage { // Error message.
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Create Account", action: attemptCreateAccount) // Create account button.
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
            }
        }
        .navigationTitle("Create Account")
    }

    /*
     * Attempts to create an account with the provided username, password, and initial preferences.
     * If successful, activates new user and exits this view.
     * If unsuccessful, sets the error message according to the specific error
     * that occurred.
     */
    private func attemptCreateAccount() {
        errorMessage = nil
        let prefs = UserPreferences(budgetRange: budget, stayDuration: stay)
        do {
            try sessionManager.createAccount(username: username, password: password, initialPreferences: prefs)
            // On success, activates new user and exits this view.
            dismiss()
        } catch SessionManager.SessionError.usernameTaken {
            errorMessage = "That username is already taken. Please choose another."
        } catch SessionManager.SessionError.invalidInput {
            errorMessage = "Please enter a non-empty username and password."
        } catch {
            errorMessage = "Unable to create account. Please try again."
        }
    }
}

#Preview {
    NavigationStack {
        CreateAccountView(sessionManager: .shared)
    }
}

