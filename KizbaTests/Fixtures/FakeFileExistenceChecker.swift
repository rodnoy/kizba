//
//  FakeFileExistenceChecker.swift
//  KizbaTests
//
//  Canonical ``FileExistenceChecking`` test double for
//  `BinaryDiscoveryService` tests. Reports a configurable set of
//  absolute paths as "executable" without touching disk.
//
//  ## Concurrency
//
//  `FileExistenceChecking` is `Sendable`; `BinaryDiscoveryService`
//  invokes `isExecutableFile(atPath:)` from an actor context. The
//  fake therefore guards its mutable set with an `NSLock` and is
//  marked `@unchecked Sendable`.
//

import Foundation
@testable import Kizba

/// In-memory ``FileExistenceChecking`` whose set of "present"
/// executables is mutable from any thread. Backed by an `NSLock` so
/// it remains `Sendable` across the actor boundary.
final class FakeFileExistenceChecker: FileExistenceChecking, @unchecked Sendable {

    private let lock = NSLock()
    private var executable: Set<String>

    init(executable: Set<String> = []) {
        self.executable = executable
    }

    nonisolated func isExecutableFile(atPath path: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return executable.contains(path)
    }

    nonisolated func setExecutable(_ paths: Set<String>) {
        lock.lock(); defer { lock.unlock() }
        executable = paths
    }

    nonisolated func add(_ path: String) {
        lock.lock(); defer { lock.unlock() }
        executable.insert(path)
    }

    nonisolated func remove(_ path: String) {
        lock.lock(); defer { lock.unlock() }
        executable.remove(path)
    }
}
