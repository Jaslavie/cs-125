import Foundation
import Combine

// MARK: - Session Manager

/* Manages user session state with persistent storage across app launches.
 * Stores user preferences (budget range and stay duration) in UserDefaults and provides
 * observable updates when preferences change. Includes debug logging to track preference changes.
 *
 * Attributes:
 * - shared: Singleton instance for global access.
 * - userPreferences: Published property containing budget and stay preferences; automatically saves and logs on change.
 */
class SessionManager: ObservableObject {
    static let shared = SessionManager()  // Singleton instance for global access
    
    /*
     * User's stored preferences (budget and stay duration).
     * Changes trigger automatic save to UserDefaults and debug logging.
     */
    @Published var userPreferences: UserPreferences {
        didSet {
            save()  // Persist to UserDefaults
            logPreferencesChange()  // Print debug log
        }
    }
    
    private let defaults = UserDefaults.standard  // iOS persistent storage
    private let preferencesKey = "userPreferences"  // Key for UserDefaults storage
    
    /*
     * Initializes the SessionManager and loads stored preferences from UserDefaults.
     * If no stored preferences exist, initializes with medium budget and medium stay duration.
     */
    private init() {
        // Attempt to load stored preferences from UserDefaults
        if let data = defaults.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.userPreferences = decoded  // Load stored preferences
            print("[SessionManager] Loaded preferences from storage:")
            print("  Budget: \(decoded.budgetRange.rawValue)")
            print("  Stay Duration: \(decoded.stayDuration.rawValue)")
        } else {
            // No stored preferences; use defaults
            self.userPreferences = UserPreferences(
                budgetRange: .medium,
                stayDuration: .medium
            )
            print("[SessionManager] Initialized with default preferences (medium budget, medium stay)")
        }
    }
    
    /*
     * Saves current preferences to UserDefaults for persistence across app launches.
     * Called automatically when userPreferences changes via didSet.
     */
    private func save() {
        if let encoded = try? JSONEncoder().encode(userPreferences) {
            defaults.set(encoded, forKey: preferencesKey)  // Persist to storage
        }
    }
    
    /*
     * Logs preference changes to console for debugging.
     * Called automatically when userPreferences changes via didSet.
     */
    private func logPreferencesChange() {
        print("[SessionManager] Preferences updated:")
        print("  Budget: \(userPreferences.budgetRange.rawValue)")
        print("  Stay Duration: \(userPreferences.stayDuration.rawValue)")
    }
    
    /*
     * Updates the stored budget range preference.
     * Triggers save and debug logging via published property didSet.
     *
     * Parameters:
     * - newBudget: The new budget range preference to store.
     */
    func updateBudgetRange(_ newBudget: BudgetRangePreference) {
        userPreferences.budgetRange = newBudget
    }
    
    /*
     * Updates the stored stay duration preference.
     * Triggers save and debug logging via published property didSet.
     *
     * Parameters:
     * - newStay: The new stay duration preference to store.
     */
    func updateStayDuration(_ newStay: StayTimePreference) {
        userPreferences.stayDuration = newStay
    }
}
