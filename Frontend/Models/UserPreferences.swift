import Foundation

enum PriceSensitivity: String, Codable {    // how sensitive the user is to price
    case thrifty                                // user is more sensitive to price
    case convenience                            // user is less sensitive to price
}

struct UserPreferences: Codable {
    var budget: Double                      // max price, in USD, user willing to spend on parking
    var priceSensitivity: PriceSensitivity  // sensitivity of price? not really sure as of now
}