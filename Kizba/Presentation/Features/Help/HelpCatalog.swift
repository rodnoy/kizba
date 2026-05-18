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
    ///
    /// IMPORTANT — append-only: new topics MUST be added at the end
    /// of this array. Block / section identifiers are positional
    /// (`"<topicID>/<sectionIndex>/<blockIndex>"`) and several tests
    /// in `HelpCatalogTests` assume the existing ordering. Inserting
    /// a topic in the middle is API-stable but rearranges nothing
    /// observable — still, keep new topics at the bottom so future
    /// readers can match accessors to sidebar order at a glance.
    public static let all: [HelpTopic] = [
        Self.makeAEADMDCCompatibility(),
        Self.makeSetupPassAndGPG(),
        Self.makeSetupGitRemote(),
        Self.makeConfigurePinentry(),
        Self.makeTouchIDProtection(),
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

    /// First-class accessor for the pass-store / GPG bootstrap topic.
    public static var setupPassAndGPG: HelpTopic {
        guard let topic = all.first(where: { $0.id == "setup-pass-and-gpg" }) else {
            return Self.makeSetupPassAndGPG()
        }
        return topic
    }

    /// First-class accessor for the git-remote sync topic.
    public static var setupGitRemote: HelpTopic {
        guard let topic = all.first(where: { $0.id == "setup-git-remote" }) else {
            return Self.makeSetupGitRemote()
        }
        return topic
    }

    /// First-class accessor for the pinentry-mac configuration topic.
    public static var configurePinentry: HelpTopic {
        guard let topic = all.first(where: { $0.id == "configure-pinentry" }) else {
            return Self.makeConfigurePinentry()
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

    /// Build the pass-store / GPG bootstrap topic. Walks a first-time
    /// user from a clean macOS box to a working `pass` install with
    /// a usable GPG identity. Commands assume Homebrew is already
    /// installed (the standard macOS dev baseline); a missing
    /// Homebrew is out of scope for this topic.
    private static func makeSetupPassAndGPG() -> HelpTopic {
        let topicID = "setup-pass-and-gpg"

        // Section 1 — Install via Homebrew
        let section1 = makeSection(
            topicID: topicID,
            sectionIndex: 0,
            heading: "Step 1 — Install via Homebrew",
            blocks: [
                .paragraph(
                    text: "Kizba is a UI on top of the standard `pass` (passwordstore.org) and GnuPG toolchain — both must be installed locally. The single command below pulls in `pass` and a current GnuPG 2.x. If Homebrew itself isn't installed yet, grab it from brew.sh first."
                ),
                .commandSequence(
                    label: "Install pass and GnuPG",
                    commands: [
                        "brew install pass gnupg",
                    ],
                    note: "Safe to re-run: Homebrew is a no-op when both formulae are already present."
                ),
            ]
        )

        // Section 2 — Generate a GPG key
        let section2 = makeSection(
            topicID: topicID,
            sectionIndex: 1,
            heading: "Step 2 — Generate a GPG key",
            blocks: [
                .paragraph(
                    text: "`pass` encrypts every entry to a GPG public key, so you need one. The interactive wizard below asks for key type (choose `RSA and RSA`, 4096 bits), expiration (`0` = never is fine for personal use), and an identity (your name + email)."
                ),
                .command(
                    label: "Generate a new key pair",
                    command: "gpg --full-generate-key",
                    note: "Pick RSA / 4096 bits / never expires for a no-fuss personal key. Set a passphrase you can actually remember."
                ),
                .warning(
                    text: "The passphrase protects your private key. There is no recovery: lose it and every password you ever stored becomes unreadable. Back up your passphrase the way you'd back up a master password."
                ),
            ]
        )

        // Section 3 — Initialize the store
        let section3 = makeSection(
            topicID: topicID,
            sectionIndex: 2,
            heading: "Step 3 — Initialize the store",
            blocks: [
                .paragraph(
                    text: "`pass init` creates `~/.password-store` and binds it to the GPG key you just generated. `<your-gpg-id>` is either the email you used in the wizard or the long key id."
                ),
                .command(
                    label: "List your secret keys to find the id",
                    command: "gpg --list-secret-keys --keyid-format LONG",
                    note: "Look for the 16-character id after `sec  rsa4096/` — that's your key id. Your email also works."
                ),
                .command(
                    label: "Initialise the store",
                    command: "pass init <your-gpg-id>",
                    note: "Replace `<your-gpg-id>` with the email or 16-character key id from the previous command."
                ),
            ]
        )

        // Section 4 — Verify it works
        let section4 = makeSection(
            topicID: topicID,
            sectionIndex: 3,
            heading: "Step 4 — Verify it works",
            blocks: [
                .paragraph(
                    text: "Round-trip a throwaway entry to confirm the encrypt / decrypt path is wired up. `pass insert` will prompt for a value; `pass <path>` decrypts it. If both succeed, Kizba will too."
                ),
                .commandSequence(
                    label: "Insert and read a test entry",
                    commands: [
                        "pass insert test/example",
                        "pass test/example",
                    ],
                    note: "Delete it afterwards with `pass rm test/example` if you want a clean store."
                ),
            ]
        )

        // Section 5 — Troubleshooting
        let section5 = makeSection(
            topicID: topicID,
            sectionIndex: 4,
            heading: "Step 5 — Troubleshooting",
            blocks: [
                .warning(
                    text: "If `pass init` reports `gpg: <id>: skipped: No public key` or `pass` returns `gpg: decryption failed: No secret key`, GnuPG can't find the key id you passed in. Run `gpg --list-secret-keys` to confirm the key exists and re-run `pass init` with the exact email or fingerprint shown there."
                ),
                .paragraph(
                    text: "Reference docs: [passwordstore.org](https://www.passwordstore.org) for `pass` itself, [gnupg.org](https://www.gnupg.org/documentation) for GPG. If passphrase prompts never appear, see the separate `Configure pinentry-mac` Help topic."
                ),
            ]
        )

        return HelpTopic(
            id: topicID,
            title: "Install pass-store and GPG",
            subtitle: "Bootstrap a working `pass` + GnuPG environment on macOS from a clean install.",
            sections: [section1, section2, section3, section4, section5]
        )
    }

    /// Build the git-remote sync topic. Assumes the user has already
    /// completed the pass / GPG bootstrap topic — this one only
    /// covers turning a local store into a multi-device store via
    /// `pass git`.
    private static func makeSetupGitRemote() -> HelpTopic {
        let topicID = "setup-git-remote"

        // Section 1 — Initialize git in your store
        let section1 = makeSection(
            topicID: topicID,
            sectionIndex: 0,
            heading: "Step 1 — Initialize git in your store",
            blocks: [
                .paragraph(
                    text: "`pass git init` creates `~/.password-store/.git` and starts tracking your encrypted entries. Every later `pass insert`, `pass edit` and `pass rm` automatically commits — you do not need to run `git add` yourself."
                ),
                .command(
                    label: "Turn the store into a git repository",
                    command: "pass git init",
                    note: "Safe to run on an existing store: it commits the current contents as the initial commit."
                ),
            ]
        )

        // Section 2 — Add a remote
        let section2 = makeSection(
            topicID: topicID,
            sectionIndex: 1,
            heading: "Step 2 — Add a remote",
            blocks: [
                .paragraph(
                    text: "Use a private repository — your store contains encrypted secrets, but you still want zero exposure of metadata (entry paths). Private GitHub, private GitLab, Gitea, or any self-hosted git server all work; `pass git` is plain git underneath."
                ),
                .command(
                    label: "Bind a remote called `origin`",
                    command: "pass git remote add origin <your-repo-url>",
                    note: "Replace `<your-repo-url>` with the SSH or HTTPS URL of your private repo, e.g. `git@github.com:you/password-store.git`."
                ),
            ]
        )

        // Section 3 — First push
        let section3 = makeSection(
            topicID: topicID,
            sectionIndex: 2,
            heading: "Step 3 — First push",
            blocks: [
                .command(
                    label: "Push the local branch and set upstream",
                    command: "pass git push -u origin main",
                    note: "The `-u` flag binds the local branch to the remote so later `pass git push` / `pass git pull` work without arguments."
                ),
                .warning(
                    text: "Some hosts (and older `git` installs) still default to `master` instead of `main`. Run `pass git branch` to see your local branch name and swap `main` for `master` in the push command if needed."
                ),
            ]
        )

        // Section 4 — Sync between devices
        let section4 = makeSection(
            topicID: topicID,
            sectionIndex: 3,
            heading: "Step 4 — Sync between devices",
            blocks: [
                .paragraph(
                    text: "On every other machine, clone the same remote into `~/.password-store` (and import the same GPG key) — then the loop below keeps every device in step. Pull before you edit, push after."
                ),
                .commandSequence(
                    label: "Pull, edit, push loop",
                    commands: [
                        "pass git pull --rebase",
                        "# make changes via pass insert / pass edit / pass rm",
                        "pass git push",
                    ],
                    note: "`--rebase` keeps the history linear so concurrent edits from different machines don't produce merge commits."
                ),
            ]
        )

        // Section 5 — Conflicts
        let section5 = makeSection(
            topicID: topicID,
            sectionIndex: 4,
            heading: "Step 5 — Conflicts",
            blocks: [
                .warning(
                    text: "Git cannot 3-way-merge `.gpg` files: the ciphertext is opaque. If two machines edit the same entry between pulls, you must resolve manually — decrypt both sides with `gpg --decrypt`, merge the plaintext by hand, re-encrypt with `gpg --encrypt -r <your-gpg-id>`, then `pass git add <file>` and `pass git commit` to finish the rebase."
                ),
                .paragraph(
                    text: "Easiest prevention: always run `pass git pull --rebase` before editing on a device you haven't touched in a while. Conflicts that do occur are rare and localised to single entries."
                ),
            ]
        )

        return HelpTopic(
            id: topicID,
            title: "Sync your store via Git",
            subtitle: "Turn `~/.password-store` into a multi-device store using `pass git` and a private remote.",
            sections: [section1, section2, section3, section4, section5]
        )
    }

    /// Build the pinentry-mac configuration topic. Covers the
    /// macOS-specific frontend that makes GPG passphrase prompts
    /// appear as native dialogs instead of failing silently in
    /// non-TTY contexts (which includes Kizba).
    private static func makeConfigurePinentry() -> HelpTopic {
        let topicID = "configure-pinentry"

        // Section 1 — Install pinentry-mac
        let section1 = makeSection(
            topicID: topicID,
            sectionIndex: 0,
            heading: "Step 1 — Install pinentry-mac",
            blocks: [
                .paragraph(
                    text: "`pinentry-mac` is a native macOS dialog that GnuPG calls whenever it needs your key passphrase. Without it, GPG falls back to a terminal prompt — which never appears when Kizba (or any other GUI app) invokes GPG, so decryption silently fails."
                ),
                .command(
                    label: "Install via Homebrew",
                    command: "brew install pinentry-mac",
                    note: nil
                ),
            ]
        )

        // Section 2 — Find the binary path
        let section2 = makeSection(
            topicID: topicID,
            sectionIndex: 1,
            heading: "Step 2 — Find the binary path",
            blocks: [
                .paragraph(
                    text: "GnuPG needs the absolute path to the pinentry binary. The location depends on your Mac's architecture: Apple Silicon (M1+) installs to `/opt/homebrew/bin/pinentry-mac`, Intel to `/usr/local/bin/pinentry-mac`."
                ),
                .command(
                    label: "Print the resolved path",
                    command: "which pinentry-mac",
                    note: "Copy the output verbatim — you will paste it into the agent config in the next step."
                ),
                .warning(
                    text: "Do not guess the path or copy it from another machine. Apple Silicon and Intel diverge, and passing the wrong path makes the agent fail with `Invalid value passed to PIN` on every prompt."
                ),
            ]
        )

        // Section 3 — Configure gpg-agent
        let section3 = makeSection(
            topicID: topicID,
            sectionIndex: 2,
            heading: "Step 3 — Configure gpg-agent",
            blocks: [
                .paragraph(
                    text: "Append a `pinentry-program` line to `~/.gnupg/gpg-agent.conf` pointing at the path you just discovered. The snippet below uses the Apple Silicon path — substitute the Intel path (`/usr/local/bin/pinentry-mac`) if `which` printed that instead."
                ),
                .commandSequence(
                    label: "Write the agent config (Apple Silicon path)",
                    commands: [
                        "mkdir -p ~/.gnupg",
                        "echo 'pinentry-program /opt/homebrew/bin/pinentry-mac' >> ~/.gnupg/gpg-agent.conf",
                    ],
                    note: "On Intel Macs, replace the path with `/usr/local/bin/pinentry-mac` before running the second line."
                ),
                .warning(
                    text: "If the file already contains a `pinentry-program` line for a different binary, edit `~/.gnupg/gpg-agent.conf` by hand instead of appending — two lines will leave whichever appears last in effect, which is rarely what you want."
                ),
            ]
        )

        // Section 4 — Restart the agent
        let section4 = makeSection(
            topicID: topicID,
            sectionIndex: 3,
            heading: "Step 4 — Restart the agent",
            blocks: [
                .paragraph(
                    text: "`gpg-agent` reads its config once at startup, so it must be restarted to pick up the new pinentry. `gpgconf --kill` is safe: the agent relaunches on the next GPG call with the updated config."
                ),
                .command(
                    label: "Stop the running agent",
                    command: "gpgconf --kill gpg-agent",
                    note: nil
                ),
            ]
        )

        // Section 5 — Smoke test
        let section5 = makeSection(
            topicID: topicID,
            sectionIndex: 4,
            heading: "Step 5 — Smoke test",
            blocks: [
                .paragraph(
                    text: "Sign a throwaway string to force a passphrase prompt. A native pinentry-mac dialog should appear — that confirms Kizba will also see the dialog when it next decrypts an entry."
                ),
                .command(
                    label: "Sign test input",
                    command: "echo \"test\" | gpg --clearsign",
                    note: "If a terminal prompt appears instead (or nothing happens), recheck the path in `~/.gnupg/gpg-agent.conf` and re-run Step 4."
                ),
            ]
        )

        return HelpTopic(
            id: topicID,
            title: "Configure pinentry-mac",
            subtitle: "Make GPG passphrase prompts appear as native macOS dialogs so Kizba can decrypt entries.",
            sections: [section1, section2, section3, section4, section5]
        )
    }

    private static func makeTouchIDProtection() -> HelpTopic {
        let topicID = "touch-id-protection"

        let section1 = makeSection(
            topicID: topicID,
            sectionIndex: 0,
            heading: "What Touch ID protection covers",
            blocks: [
                .paragraph(
                    text: "Touch ID protection can gate three sensitive actions: revealing a password, copying a password, and copying sensitive metadata values."
                ),
                .paragraph(
                    text: "When the policy is enabled, Kizba asks for Touch ID before these actions continue."
                ),
            ]
        )

        let section2 = makeSection(
            topicID: topicID,
            sectionIndex: 1,
            heading: "Sensitive metadata whitelist",
            blocks: [
                .paragraph(
                    text: "Metadata keys are matched case-insensitively. Touch ID gating applies only to this whitelist:"
                ),
                .bulletList(items: [
                    "password",
                    "pin",
                    "token",
                    "secret",
                    "otpauth",
                    "key",
                ]),
            ]
        )

        let section3 = makeSection(
            topicID: topicID,
            sectionIndex: 2,
            heading: "What is not gated",
            blocks: [
                .paragraph(
                    text: "Username copy is not gated."
                ),
                .paragraph(
                    text: "Non-sensitive metadata is not gated, including keys such as notes, url, email, and comment."
                ),
            ]
        )

        let section4 = makeSection(
            topicID: topicID,
            sectionIndex: 3,
            heading: "Graceful fallback behavior",
            blocks: [
                .paragraph(
                    text: "If biometrics are unavailable on this Mac, reveal and copy actions continue without blocking."
                ),
                .warning(
                    text: "If authentication is cancelled or fails, Kizba silently skips the action (no clipboard write, no extra error banner)."
                ),
            ]
        )

        let section5 = makeSection(
            topicID: topicID,
            sectionIndex: 4,
            heading: "How to enable it",
            blocks: [
                .paragraph(
                    text: "Open Settings → Security and enable \"Require Touch ID for sensitive actions\"."
                ),
            ]
        )

        return HelpTopic(
            id: topicID,
            title: "Touch ID protection",
            subtitle: "Control which sensitive reveal and copy actions require Touch ID.",
            sections: [section1, section2, section3, section4, section5]
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
