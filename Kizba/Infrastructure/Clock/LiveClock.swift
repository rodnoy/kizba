import Foundation

public struct LiveClock: ClockServicing {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
