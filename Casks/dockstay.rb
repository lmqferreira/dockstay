cask "dockstay" do
  version "1.0.0"
  sha256 "342172f8900d16f3d0255613d50e2624dc84fd9d0fa648df5cf48128402be775"

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
