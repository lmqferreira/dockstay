cask "dockstay" do
  version "1.0.0"
  sha256 "008dc2ec40e45c5474292bf9b35268156cc65eac645d77a5d0cf64308b06fc2d"

  url "https://github.com/lmqferreira/dockstay/releases/download/v#{version}/dockstay-arm64.zip"
  name "DockStay"
  desc "Pin your Mac Dock to one screen"
  homepage "https://github.com/lmqferreira/dockstay"

  depends_on macos: ">= :ventura"

  binary "dockstay"

  zap trash: [
    "~/Library/Preferences/com.lmqferreira.dockstay.plist",
  ]
end
