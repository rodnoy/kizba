cask "kizba" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/rodnoy/kizba/releases/download/v#{version}/Kizba-v#{version}.zip"
  name "Kizba"
  desc "Native macOS GUI for the pass password manager"
  homepage "https://github.com/rodnoy/kizba"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Kizba.app"

  zap trash: [
    "~/Library/Preferences/app.kizba.Kizba.plist",
    "~/Library/Application Support/Kizba",
    "~/Library/Caches/app.kizba.Kizba",
    "~/Library/Saved Application State/app.kizba.Kizba.savedState",
  ]

  caveats <<~EOS
    Kizba is ad-hoc signed (no Apple Developer ID). On first launch macOS
    Gatekeeper may block it. To allow:

      1. Install with --no-quarantine (recommended):
         brew install --cask --no-quarantine kizba

      2. Or after install, run:
         xattr -dr com.apple.quarantine /Applications/Kizba.app

      3. Or right-click Kizba.app → Open the first time.

    Runtime dependencies (install separately if not present):
      brew install pass gnupg pinentry-mac

    NOTE: This is a placeholder cask. The first release via the GitHub
    Actions workflow will overwrite this file with real version + sha256.
  EOS
end
