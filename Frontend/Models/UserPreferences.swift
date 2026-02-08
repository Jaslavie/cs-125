import Foundation

enum PriceSensitivity: String, Codable {
    case thrifty
    case convenience
}

struct UserPreferences: Codable {
    var budget: Double                      // max price, in USD, user willing to spend on parking
    var priceSensitivity: PriceSensitivity  // sensitivity of price? not really sure as of now
}