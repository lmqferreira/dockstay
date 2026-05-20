cask "dockstay" do
  version "1.0.1"
  sha256 "4f2936f19b19324a416777da41736655c15bf9d79837de61d9cf768e7163665d"

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
