import Foundation
import Combine

// MARK: - Session Manager

/* Manages multi-user session state with persistent storage across app launches.
 * Stores a list of usernames, per-user credentials (username → password), and per-user
 * preferences (username → budget range, username → stay duration) in UserDefaults and
 * provides observable updates when the active user or their preferences change.
 *
 * WARNING: Passwords are stored in plaintext for demo/class purposes only and must
 * not be used with real credentials in production.
 *
 * Attributes:
 * - shared: Singleton instance for global access.
 * - currentUsername: Published name of the logged-in user (nil when logged out).
 * - userPreferences: Published property containing the active user's budget and stay preferences;
 *   automatically saves and logs on change.
 */
class SessionManager: ObservableObject {
    static let shared = SessionManager()  // Singleton instance for global access

    /// Username of the currently logged-in user (nil when no user is authenticated).
    @Published var currentUsername: String? {
        didSet {
            guard isFullyInitialized else { return }
            save()
            logSessionChange()
        }
    }

    /*
     * Active user's stored preferences (budget and stay duration).
     * Changes trigger automatic save to UserDefaults and debug logging.
     */
    @Published var userPreferences: UserPreferences {
        didSet {
            guard isFullyInitialized else { return }
            // Persist updated preferences for the active user and log the change.
            if let username = currentUsername {
                budgetByUsername[username] = userPreferences.budgetRange
                stayByUsername[username] = userPreferences.stayDuration
            }
            save()
            logPreferencesChange()
        }
    }

    // MARK: - Private storage

    /// When false, didSet observers skip save/log so init can set currentUsername and userPreferences without triggering side effects that require self to be fully initialized.
    private var isFullyInitialized = false

    private let defaults = UserDefaults.standard  // iOS persistent storage

    // Keys for UserDefaults storage
    private let usernamesKey = "SessionManager.usernames"
    private let passwordsKey = "SessionManager.passwords"
    private let budgetKey = "SessionManager.budgetByUsername"
    private let stayKey = "SessionManager.stayByUsername"
    private let lastUsernameKey = "SessionManager.lastUsername"

    // In-memory collections backing the multi-user model.
    private var usernames: [String] = []
    private var passwordsByUsername: [String: String] = [:]
    private var budgetByUsername: [String: BudgetRangePreference] = [:]
    private var stayByUsername: [String: StayTimePreference] = [:]

    // MARK: - Init

    /*
     * Initializes the SessionManager and loads stored user accounts and preferences from UserDefaults.
     * If no accounts exist, initializes with no current user and neutral medium/medium preferences.
     * Debug logs print the currentUsername (if any) and that user's decoded preferences.
     */
    private init() {
        // Load usernames
        if let storedUsernames = defaults.stringArray(forKey: usernamesKey) {
            usernames = storedUsernames
        }

        // Load passwords
        if let storedPasswords = defaults.dictionary(forKey: passwordsKey) as? [String: String] {
            passwordsByUsername = storedPasswords
        }

        // Load budget preferences (rawValue string → enum)
        if let storedBudget = defaults.dictionary(forKey: budgetKey) as? [String: String] {
            var decoded: [String: BudgetRangePreference] = [:]
            for (user, raw) in storedBudget {
                decoded[user] = BudgetRangePreference(rawValue: raw) ?? .medium
            }
            budgetByUsername = decoded
        }

        // Load stay preferences (rawValue string → enum)
        if let storedStay = defaults.dictionary(forKey: stayKey) as? [String: String] {
            var decoded: [String: StayTimePreference] = [:]
            for (user, raw) in storedStay {
                decoded[user] = StayTimePreference(rawValue: raw) ?? .medium
            }
            stayByUsername = decoded
        }

        // Restore last username if it still exists
        let lastUsername = defaults.string(forKey: lastUsernameKey)
        let restoredUsername: String?
        if let last = lastUsername, usernames.contains(last) {
            restoredUsername = last
        } else {
            restoredUsername = nil
        }

        // Derive initial active preferences so userPreferences is initialized before currentUsername 
        if let username = restoredUsername,
           let budget = budgetByUsername[username],
           let stay = stayByUsername[username] {
            userPreferences = UserPreferences(budgetRange: budget, stayDuration: stay)
        } else {
            userPreferences = UserPreferences(budgetRange: .medium, stayDuration: .medium)
        }

        currentUsername = restoredUsername
        isFullyInitialized = true
        save()
        logStartupState()
    }

    // MARK: - Persistence

    /*
     * Encodes and saves user account lists and per-user preferences to UserDefaults for
     * persistence across app launches. Called automatically when the active user or
     * their preferences change.
     */
    private func save() {
        defaults.set(usernames, forKey: usernamesKey)
        defaults.set(passwordsByUsername, forKey: passwordsKey)

        // Persist enum dictionaries as rawValue strings.
        let budgetRaw = Dictionary(uniqueKeysWithValues: budgetByUsername.map { ($0.key, $0.value.rawValue) })
        let stayRaw = Dictionary(uniqueKeysWithValues: stayByUsername.map { ($0.key, $0.value.rawValue) })
        defaults.set(budgetRaw, forKey: budgetKey)
        defaults.set(stayRaw, forKey: stayKey)

        defaults.set(currentUsername, forKey: lastUsernameKey)
    }

    // MARK: - Logging

    /*
     * Logs the active user and their current preferences on startup.
     */
    private func logStartupState() {
        let userLabel = currentUsername ?? "(none)"
        print("[SessionManager] Startup state:")
        print("  Current user: \(userLabel)")
        print("  Budget: \(userPreferences.budgetRange.rawValue)")
        print("  Stay Duration: \(userPreferences.stayDuration.rawValue)")
    }

    /*
     * Logs preference changes to console for debugging.
     * Called automatically when userPreferences changes via didSet.
     */
    private func logPreferencesChange() {
        let userLabel = currentUsername ?? "(none)"
        print("[SessionManager] Preferences updated for user: \(userLabel)")
        print("  Budget: \(userPreferences.budgetRange.rawValue)")
        print("  Stay Duration: \(userPreferences.stayDuration.rawValue)")
    }

    /*
     * Logs session (login/logout) changes to console.
     */
    private func logSessionChange() {
        let userLabel = currentUsername ?? "(none)"
        print("[SessionManager] Active user changed: \(userLabel)")
    }

    // MARK: - Public API

    /// Errors surfaced to the UI for login and account-creation flows.
    enum SessionError: Error {
        case usernameTaken
        case usernameNotFound
        case incorrectPassword
        case invalidInput
    }

    /*
     * Creates a new account with the given username, password, and initial preferences.
     * On success, sets the new user as the active session.
     */
    func createAccount(username: String, password: String, initialPreferences: UserPreferences) throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            throw SessionError.invalidInput
        }
        guard !usernames.contains(trimmedUsername) else {
            throw SessionError.usernameTaken
        }

        usernames.append(trimmedUsername)
        passwordsByUsername[trimmedUsername] = password
        budgetByUsername[trimmedUsername] = initialPreferences.budgetRange
        stayByUsername[trimmedUsername] = initialPreferences.stayDuration

        currentUsername = trimmedUsername
        userPreferences = initialPreferences
        save()
        print("[SessionManager] Created account for user: \(trimmedUsername)")
    }

    /*
     * Attempts to log in with the provided username and password. On success, sets
     * the active user and loads their stored preferences (or neutral defaults if missing).
     */
    func login(username: String, password: String) throws {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            throw SessionError.invalidInput
        }
        guard usernames.contains(trimmedUsername) else {
            throw SessionError.usernameNotFound
        }
        guard passwordsByUsername[trimmedUsername] == password else {
            throw SessionError.incorrectPassword
        }

        currentUsername = trimmedUsername

        let budget = budgetByUsername[trimmedUsername] ?? .medium
        let stay = stayByUsername[trimmedUsername] ?? .medium
        userPreferences = UserPreferences(budgetRange: budget, stayDuration: stay)

        save()
        print("[SessionManager] Logged in as user: \(trimmedUsername)")
    }

    /*
     * Logs out the current user and reverts to neutral default preferences.
     * Does not delete any stored accounts; it simply clears the active session.
     */
    func logout() {
        currentUsername = nil
        userPreferences = UserPreferences(budgetRange: .medium, stayDuration: .medium)
        save()
        print("[SessionManager] Logged out; reverted to default preferences.")
    }

    /*
     * Updates the stored budget range preference for the active user.
     * Triggers save and debug logging via the userPreferences didSet.
     */
    func updateBudgetRange(_ newBudget: BudgetRangePreference) {
        userPreferences.budgetRange = newBudget
    }

    /*
     * Updates the stored stay duration preference for the active user.
     * Triggers save and debug logging via the userPreferences didSet.
     */
    func updateStayDuration(_ newStay: StayTimePreference) {
        userPreferences.stayDuration = newStay
    }
}
