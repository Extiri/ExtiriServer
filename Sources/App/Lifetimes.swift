import Foundation

class Lifetimes {
  static func getDate(for time: Double) -> Date {
    Date(timeIntervalSinceNow: time)
  }
  
  static func hasTimePassed(for date: Date, with lifetime: Double) -> Bool {
    lifetime < Date().timeIntervalSince(date)
  }
  
  static let tokenLifetime = Double(60 * 60 * 24 * 30)
  static let confirmationTime = Double(60 * 60 * 24)
  static let passwordChangeTime = Double(60 * 60 * 24)
  static let accountDeletionTime = Double(60 * 60 * 24 * 7)
}
