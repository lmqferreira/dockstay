cask "dockstay" do
  version "1.0.0"
  sha256 "7da665e1924d1bb9fdcee2d11424f3d75cd3504badb9622b7c321747317a7da3"

  url "https://github.com/lmqferreira/dockstay/releases/download/v#{version}/dockstay-arm64.zip"
  name "DockStay"
  desc "Pin your Mac Dock to one screen"
  homepage "https://github.com/lmqferreira/dockstay"

  depends_on macos: ">= :ventura"

  binary "dockstay"

  postflight do
    system_command "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", "#{staged_path}/dockstay"]
  end

  zap trash: [
    "~/Library/Preferences/com.lmqferreira.dockstay.plist",
  ]
end
