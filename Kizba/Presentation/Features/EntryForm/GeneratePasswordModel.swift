//
//  GeneratePasswordModel.swift
//  Kizba
//
//  Phase F.4 — `@Observable @MainActor` view-model for the
//  Generate Password sub-sheet hosted by `NewEntrySheet`. Lifecycle
//  is bounded by the sub-sheet's presentation: SwiftUI constructs
//  the model when the sheet appears and discards it on dismissal,
//  so the cleartext preview leaves memory as soon as the user is
//  done with it.
//
//  Contract:
//
//    1. SwiftUI constructs the model with a ``PasswordGenerating``
//       collaborator (production: ``LivePasswordGenerator``).
//    2. ``init(generator:)`` immediately produces an initial preview
//       so the sheet opens with a non-empty value (no flash-of-empty).
//    3. The view binds to ``length`` and ``includeSymbols`` and is
//       responsible for calling ``regenerate()`` after either
//       changes — typically via SwiftUI `.onChange`. We intentionally
//       do NOT auto-regenerate inside `didSet`: a `Stepper`'s commit
//       semantics map cleanly onto a single `.onChange` event, but a
//       hypothetical free-text input would not. Letting the view own
//       the trigger keeps the model agnostic of the input affordance.
//    4. The host `NewEntrySheet` reads ``previewPassword`` and applies
//       it to its own `EntryFormModel.draft.password` via an
//       `onApply` callback — the sub-sheet never touches the parent
//       form's draft directly (decoupling).
//
//  Per `.ai/decisions.md`, the previewed password is never logged
//  and never crosses the toast boundary.
//

import Foundation
import Observation

/// View-model backing ``GeneratePasswordSheet``.
///
/// `internal` access matches the rest of the EntryForm feature:
/// the model is part of the Presentation layer and is wired by the
/// same internal SwiftUI surface (`NewEntrySheet`).
@Observable
@MainActor
final class GeneratePasswordModel {

    /// Discrete state of the preview pipeline.
    ///
    /// `.idle` is the initial pre-generation state and is observable
    /// only through tests that bypass the standard init flow — the
    /// production init runs ``regenerate()`` synchronously, so the
    /// view always sees `.ready` (or `.error` on truly invalid input).
    enum State: Sendable, Equatable {
        case idle
        case ready(password: String)
        /// User-facing message; never includes the raw error or any
        /// payload from the generator.
        case error(String)
    }

    // MARK: - Observable state

    /// Current preview state. Mutated only via ``regenerate()``.
    private(set) var state: State = .idle

    /// Requested length. Bindable so a `Stepper` can target it. The
    /// view triggers ``regenerate()`` from `.onChange` after the
    /// stepper commits a new value.
    var length: Int = 25

    /// Whether to include `pass generate`'s default symbol set in the
    /// pool. Bindable so a `Toggle` can target it. The view triggers
    /// ``regenerate()`` from `.onChange` after the toggle flips.
    var includeSymbols: Bool = true

    /// UI-level bounds for the length stepper. Defined here (not in
    /// the view) so tests can pin the contract without rendering
    /// SwiftUI. Matches the project's typical 8...128 range; the
    /// underlying ``PasswordGenerating`` only enforces the lower
    /// bound (`> 0`).
    static let lengthBounds: ClosedRange<Int> = 8...128

    // MARK: - Dependencies

    private let generator: any PasswordGenerating

    // MARK: - Init

    /// Construct and immediately produce an initial preview so the
    /// sheet opens populated. If the generator throws on the default
    /// length (it should not for the default `25`), the model lands
    /// in ``State/error(_:)`` and the view renders a banner.
    init(generator: any PasswordGenerating) {
        self.generator = generator
        regenerate()
    }

    // MARK: - Actions

    /// Generate a fresh preview using the current ``length`` and
    /// ``includeSymbols``. Synchronous: ``PasswordGenerating`` is a
    /// pure CSPRNG-backed call.
    func regenerate() {
        do {
            let pwd = try generator.generate(
                length: length,
                includeSymbols: includeSymbols
            )
            state = .ready(password: pwd)
        } catch {
            // Map the generator's error to a user-facing string. We
            // avoid embedding `error.localizedDescription` directly
            // because the only failure today is `invalidLength` and
            // a length-specific message is more actionable.
            state = .error(
                "Could not generate password (length \(length) outside valid range)."
            )
        }
    }

    // MARK: - Derived

    /// Current preview password if the model is in ``State/ready(password:)``;
    /// `nil` otherwise. Convenience for the view's "Use this password"
    /// button (disabled when nil) and for tests.
    var previewPassword: String? {
        if case .ready(let pwd) = state { return pwd }
        return nil
    }
}
