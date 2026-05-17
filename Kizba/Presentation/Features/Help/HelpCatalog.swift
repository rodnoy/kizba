//
//  HelpCatalog.swift
//  Kizba
//
//  Static factory producing the immutable list of `HelpTopic`
//  instances rendered by the Help window. Section / block ids are
//  assigned deterministically as `"<topicID>/<sectionIndex>"` and
//  `"<topicID>/<sectionIndex>/<blockIndex>"` so identity is stable
//  across rebuilds and assertable from tests.
//
//  Adding a new topic: append a new `HelpTopic` to ``all`` (and, if it
//  warrants top-level access, expose a typed accessor like
//  ``aeadMDCCompatibility``).
//

import Foundation

/// Compile-time catalog of Help topics shipped with Kizba.
public enum HelpCatalog {

    /// Every topic the Help window can display. Order mirrors the
    /// sidebar.
    public static let all: [HelpTopic] = [
        Self.makeAEADMDCCompatibility()
    ]

    /// First-class accessor for the AEAD/MDC compatibility topic so
    /// tests and callers can retrieve it by intent rather than by
    /// array index.
    public static var aeadMDCCompatibility: HelpTopic {
        // Force-unwrap is safe by construction: `all` is a non-empty
        // compile-time constant whose first element is built by
        // `makeAEADMDCCompatibility()` below.
        guard let topic = all.first(where: { $0.id == "aead-mdc-compatibility" }) else {
            // Construction-time invariant violated — return a freshly
            // built copy as a defensive fallback. Tests assert the
            // catalog contains the topic, so this branch is
            // unreachable in well-formed builds.
            return Self.makeAEADMDCCompatibility()
        }
        return topic
    }

    // MARK: - Topic builders

    /// Build the AEAD/MDC compatibility topic. The wording is final
    /// per the design document; Section 6's discovery script uses
    /// `find` rather than bash globstar so it works on default
    /// macOS bash 3.2 / zsh without `shopt -s globstar` (user
    /// decision D1).
    private static func makeAEADMDCCompatibility() -> HelpTopic {
        let topicID = "aead-mdc-compatibility"

        // Section 1 — What's happening
        let section1 = makeSection(
            topicID: topicID,
            sectionIndex: 0,
            heading: "What's happening",
            blocks: [
                .paragraph(
                    text: "Modern GnuPG (2.5+) writes encrypted files in a new format called AEAD. It's faster and more secure on paper, but most mobile OpenPGP clients (Pass for iOS, Android Password Store) only understand the older format called MDC (RFC 4880). When Kizba writes a new entry on macOS, those mobile clients open the file, decrypt the session key correctly with your private key, then choke on the AEAD payload and either error out or silently fail."
                ),
                .paragraph(
                    text: "Your private key is fine. The compatibility flag is stored in your public key's self-signature ('preferences'). Removing AEAD from those preferences forces every modern GnuPG (including the one Kizba uses under the hood) to fall back to MDC, which every OpenPGP client on Earth understands."
                ),
            ]
        )

        // Section 2 — Symptoms
        let section2 = makeSection(
            topicID: topicID,
            sectionIndex: 1,
            heading: "Symptoms",
            blocks: [
                .bulletList(items: [
                    "Pass for iOS shows a blank entry or 'cannot decrypt' for files created on Mac",
                    "Android Password Store throws an opaque error on Kizba-created entries",
                    "The same files open fine on macOS and inside Kizba itself",
                    "`gpg --list-packets <file>` shows `:aead encrypted packet:` (tag=20) instead of `:encrypted data packet:` (tag=18)",
                ])
            ]
        )

        // Section 3 — Step 1: Back up your key
        let section3 = makeSection(
            topicID: topicID,
            sectionIndex: 2,
            heading: "Step 1 — Back up your key (recommended)",
            blocks: [
                .commandSequence(
                    label: "Save secret + public key to your home directory",
                    commands: [
                        "gpg --export-secret-keys --armor <YOUR_KEY_ID> > ~/gpg-backup-pre-aead-fix.asc",
                        "gpg --export --armor <YOUR_KEY_ID> > ~/gpg-pubkey-backup-pre-aead-fix.asc",
                    ],
                    note: "Move these files to a safe place after you're done. Anyone with the secret-key file can impersonate you."
                ),
            ]
        )

        // Section 4 — Step 2: Remove AEAD from key preferences
        let section4 = makeSection(
            topicID: topicID,
            sectionIndex: 3,
            heading: "Step 2 — Remove AEAD from key preferences",
            blocks: [
                .warning(
                    text: "This is an INTERACTIVE command. After running it, type the commands shown below at the gpg> prompt one at a time."
                ),
                .command(
                    label: "Open the key editor",
                    command: "gpg --edit-key <YOUR_EMAIL_OR_KEY_ID>",
                    note: "Replace <YOUR_EMAIL_OR_KEY_ID> with your address or fingerprint."
                ),
                .commandSequence(
                    label: "Then at the gpg> prompt, run:",
                    commands: [
                        "setpref S9 S8 S7 S2 H10 H9 H8 H11 H2 Z2 Z3 Z1",
                        "save",
                    ],
                    note: "Confirm with 'y' when asked, then 'save' commits the change."
                ),
            ]
        )

        // Section 5 — Step 3: Verify the fix
        let section5 = makeSection(
            topicID: topicID,
            sectionIndex: 4,
            heading: "Step 3 — Verify the fix",
            blocks: [
                .command(
                    label: "Preferences should no longer list AEAD",
                    command: "gpg --edit-key <YOUR_EMAIL_OR_KEY_ID> showpref quit 2>&1 | grep -iE 'AEAD|Features'",
                    note: nil
                ),
                .command(
                    label: "A freshly encrypted file should now show tag=18, not tag=20",
                    command: "echo 'test' | gpg --encrypt --armor -r <YOUR_EMAIL_OR_KEY_ID> | gpg --list-packets | grep -E 'tag=|encrypted'",
                    note: nil
                ),
            ]
        )

        // Section 6 — Step 4: Re-encrypt existing AEAD files.
        // Per user decision D1, the discovery script uses `find`
        // instead of bash globstar so it works on default macOS
        // bash 3.2 / zsh without `shopt -s globstar`. Each line is
        // a separate string in `commands` so "Copy all" joins them
        // with `\n` and the user receives the script verbatim.
        let section6 = makeSection(
            topicID: topicID,
            sectionIndex: 5,
            heading: "Step 4 — Re-encrypt existing AEAD files",
            blocks: [
                .paragraph(
                    text: "The preferences fix only affects newly-encrypted files. Files already stored in AEAD format must be re-encrypted by re-saving them through `pass edit`. Replace the entry paths below with your own."
                ),
                .commandSequence(
                    label: "Find existing AEAD files",
                    commands: [
                        "find ~/.password-store -name '*.gpg' -type f | while read f; do",
                        "  if gpg --list-packets \"$f\" 2>/dev/null | grep -q 'aead'; then",
                        "    echo \"AEAD: $f\"",
                        "  fi",
                        "done",
                    ],
                    note: "Lists every entry in your store still using AEAD."
                ),
                .commandSequence(
                    label: "Re-save each entry through pass edit",
                    commands: [
                        "pass edit notes/example-entry",
                    ],
                    note: "Just save without changes (in vim: type :wq). Do this for each path printed above, dropping the .gpg suffix."
                ),
            ]
        )

        // Section 7 — Step 5: Sync the public key to other devices
        let section7 = makeSection(
            topicID: topicID,
            sectionIndex: 6,
            heading: "Step 5 — Sync the public key to other devices",
            blocks: [
                .paragraph(
                    text: "If you use this key on multiple machines, export the updated public key and import it everywhere else. Phones do not strictly need this — most mobile clients can't write AEAD anyway — but desktops with GnuPG 2.5+ should be updated."
                ),
                .commandSequence(
                    label: "Export updated public key",
                    commands: [
                        "gpg --export --armor <YOUR_EMAIL_OR_KEY_ID> > ~/pubkey-updated.asc",
                    ],
                    note: nil
                ),
                .command(
                    label: "If you publish to a keyserver",
                    command: "gpg --keyserver keys.openpgp.org --send-keys <YOUR_KEY_ID>",
                    note: "Skip this step if you never published your key publicly."
                ),
            ]
        )

        return HelpTopic(
            id: topicID,
            title: "Cross-client compatibility (AEAD vs MDC)",
            subtitle: "Why your iOS / Android client may silently fail to open Kizba entries — and how to fix it for good.",
            sections: [section1, section2, section3, section4, section5, section6, section7]
        )
    }

    // MARK: - Section / block id assignment

    /// Build a `HelpSection` whose id is `"<topicID>/<sectionIndex>"`
    /// and whose blocks carry deterministic
    /// `"<topicID>/<sectionIndex>/<blockIndex>"` identifiers.
    ///
    /// `BlockSpec` is a small payload-only mirror of `HelpBlock` that
    /// omits the id field; the catalog assigns ids here so call sites
    /// stay readable.
    private static func makeSection(
        topicID: String,
        sectionIndex: Int,
        heading: String,
        blocks: [BlockSpec]
    ) -> HelpSection {
        let sectionID = "\(topicID)/\(sectionIndex)"
        let materialised: [HelpBlock] = blocks.enumerated().map { index, spec in
            let blockID = "\(sectionID)/\(index)"
            switch spec {
            case let .paragraph(text):
                return .paragraph(id: blockID, text: text)
            case let .warning(text):
                return .warning(id: blockID, text: text)
            case let .command(label, command, note):
                return .command(id: blockID, label: label, command: command, note: note)
            case let .commandSequence(label, commands, note):
                return .commandSequence(id: blockID, label: label, commands: commands, note: note)
            case let .bulletList(items):
                return .bulletList(id: blockID, items: items)
            }
        }
        return HelpSection(id: sectionID, heading: heading, body: materialised)
    }

    /// Internal payload-only mirror of `HelpBlock` used during
    /// catalog construction. Lets call sites omit deterministic ids.
    private enum BlockSpec {
        case paragraph(text: String)
        case warning(text: String)
        case command(label: String?, command: String, note: String?)
        case commandSequence(label: String?, commands: [String], note: String?)
        case bulletList(items: [String])
    }
}
