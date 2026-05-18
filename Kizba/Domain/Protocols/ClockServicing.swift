import Foundation

/// Abstraction over wall-clock time for testability.
public protocol ClockServicing: Sendable {
    /// Current wall-clock date.
    func now() -> Date
}
