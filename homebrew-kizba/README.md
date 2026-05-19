# Homebrew Kizba

Homebrew tap for [Kizba](https://github.com/rodnoy/kizba) — native macOS GUI for the `pass` password manager.

## Install

```sh
brew tap rodnoy/kizba
brew install --cask --no-quarantine kizba
```

The `--no-quarantine` flag is required because Kizba is ad-hoc signed (no Apple Developer account).

If you forgot the flag, run after install:

```sh
xattr -dr com.apple.quarantine /Applications/Kizba.app
```

## Runtime dependencies

Kizba shells out to `pass`, `gpg`, and `pinentry-mac` at runtime. Install them separately:

```sh
brew install pass gnupg pinentry-mac
```

See the Kizba Help app for full setup guidance.

## Updates

`brew upgrade --cask kizba` pulls the latest release published to this tap by the [Kizba release workflow](https://github.com/rodnoy/kizba/actions).

## License

MIT — see `LICENSE` in this repo and in the main Kizba repo.
