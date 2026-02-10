import SwiftUI

enum Theme {
    // Uber-inspired palette
    static let primary = Color.black
    static let primaryInverse = Color.white
    static let accent = Color(red: 0.0, green: 0.78, blue: 0.33)  // Uber green
    static let secondaryText = Color.gray
    static let cardBackground = Color.white
    static let cardShadow = Color.black.opacity(0.08)
    static let divider = Color.gray.opacity(0.3)
    
    // Map / pins
    static let pinHighlight = Color(red: 0.0, green: 0.78, blue: 0.33)
}
