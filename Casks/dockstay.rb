cask "dockstay" do
  version "1.0.0"
  sha256 "b26fb893bcca7bfea3ad6f4bc35b058a41f18ebe280fed30e6d1af58e0b75693"

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
