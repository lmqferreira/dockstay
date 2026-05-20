cask "dockstay" do
  version "1.0.0"
  sha256 "772c09ce33b504d0eac58166bb5816a7352ee5c05e35b1aab61904db6fa24b23"

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
