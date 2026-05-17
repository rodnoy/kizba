//
//  FakeRecentEntriesValidator.swift
//  KizbaTests
//
//  Test double for `RecentEntriesValidating`. Holds a mutable set of
//  paths to consider valid and counts `validate(_:)` invocations so
//  tests can assert the model actually consults the validator.
//

import Foundation
@testable import Kizba

actor FakeRecentEntriesValidator: RecentEntriesValidating {

    var validPaths: Set<String>
    private(set) var validateCalls: Int = 0

    init(validPaths: Set<String> = []) {
        self.validPaths = validPaths
    }

    func setValidPaths(_ newValue: Set<String>) {
        validPaths = newValue
    }

    func validate(_ paths: [String]) async -> [String] {
        validateCalls += 1
        return paths.filter { validPaths.contains($0) }
    }
}
