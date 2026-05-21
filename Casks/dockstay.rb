cask "dockstay" do
  version "1.0.2"
  sha256 "adc7631f2c844f506cf21117833ce8d398b923347e481fb3fbeefa54978a61db"

  url "https://github.com/lmqferreira/dockstay/releases/download/v#{version}/DockStay.zip"
  name "DockStay"
  desc "Pin your Mac Dock to one screen"
  homepage "https://github.com/lmqferreira/dockstay"

  depends_on macos: ">= :ventura"

  app "DockStay.app"

  postflight do
    system_command "/usr/bin/xattr", args: ["-cr", "#{appdir}/DockStay.app"]
  end

  zap trash: [
    "~/Library/Preferences/com.lmqferreira.dockstay.plist",
  ]
end
