import Foundation

public protocol OTPGenerating: Sendable {
    func generate(_ secret: OTPSecret, at date: Date) -> String
}
