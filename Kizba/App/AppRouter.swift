//
//  AppRouter.swift
//  Kizba
//
//  Centralised imperative router for presenting sheets, dialogs
//  and tracking selection. This file provides a minimal scaffold
//  used by Phase B (AppRouter extraction) of MVP 3.
//

import Foundation
import Observation

/// Application-level router that centralises presentation flags and
/// selection state. Designed to be used from the MainActor and to be
/// observed by SwiftUI views / view models via the Observation macro.
@Observable
@MainActor
final class AppRouter {

    // MARK: - Presentation flags

    /// Whether the New Entry sheet is presented.
    var isNewEntrySheetPresented: Bool = false

    /// Whether the Edit Entry sheet is presented.
    var isEditEntrySheetPresented: Bool = false

    /// Whether the Move Entry sheet is presented.
    var isMoveEntrySheetPresented: Bool = false

    /// Whether the In-Place Regenerate sheet is presented.
    var isRegenerateInPlaceSheetPresented: Bool = false

    /// Whether the destructive delete confirmation is presented.
    var isDeleteConfirmationPresented: Bool = false

    /// Whether the Git conflict banner sheet is presented.
    var isGitConflictBannerPresented: Bool = false

    /// Whether the Search sheet is presented.
    var isSearchSheetPresented: Bool = false

    // MARK: - Selection

    /// Currently selected folder name, or `nil` when none is selected.
    var selectedFolder: String? = nil

    /// Currently selected entry id (pass-style path), or `nil` when
    /// no entry is selected.
    var selectedEntryID: String? = nil

    // MARK: - Imperative API

    /// Present the New Entry sheet.
    func presentNewEntry() {
        isNewEntrySheetPresented = true
    }

    /// Present the Edit Entry sheet.
    func presentEditEntry() {
        isEditEntrySheetPresented = true
    }

    /// Present the Move Entry sheet.
    func presentMove() {
        isMoveEntrySheetPresented = true
    }

    /// Present the Regenerate (in-place) sheet.
    func presentRegenerate() {
        isRegenerateInPlaceSheetPresented = true
    }

    /// Present the destructive delete confirmation dialog.
    func presentDeleteConfirmation() {
        isDeleteConfirmationPresented = true
    }

    /// Present the Git conflict banner sheet.
    func presentGitConflictBanner() {
        isGitConflictBannerPresented = true
    }

    /// Present the Search sheet.
    func presentSearch() {
        isSearchSheetPresented = true
    }

    /// Dismiss the Git conflict banner sheet.
    func dismissGitConflictBanner() {
        isGitConflictBannerPresented = false
    }

    /// Dismiss the Search sheet.
    func dismissSearch() {
        isSearchSheetPresented = false
    }

    /// Dismiss all presented sheets / dialogs.
    func dismissAll() {
        isNewEntrySheetPresented = false
        isEditEntrySheetPresented = false
        isMoveEntrySheetPresented = false
        isRegenerateInPlaceSheetPresented = false
        isDeleteConfirmationPresented = false
        isGitConflictBannerPresented = false
        isSearchSheetPresented = false
    }

    /// Select a top-level folder (or clear selection by passing `nil`).
    func selectFolder(_ folder: String?) {
        selectedFolder = folder
    }

    /// Select an entry by id (or clear selection by passing `nil`).
    func selectEntry(_ id: String?) {
        selectedEntryID = id
    }
}
