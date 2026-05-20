class Dockstay < Formula
  desc "Pin your Mac Dock to one screen — no more migration between monitors"
  homepage "https://github.com/lmqferreira/dockstay"
  url "https://github.com/lmqferreira/dockstay/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "b852c3163a9f41f49bb54a1be1135419bc0a92c3176b18aed0c03dbfe5ec509e"
  license "MIT"

  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/DockStay" => "dockstay"
  end

  def caveats
    <<~EOS
      DockStay needs Accessibility permissions to intercept mouse events.
      Grant access in: System Settings → Privacy & Security → Accessibility
    EOS
  end

  service do
    run opt_bin/"dockstay"
    keep_alive true
    log_path var/"log/dockstay.log"
    error_log_path var/"log/dockstay.log"
  end

  test do
    assert_predicate bin/"dockstay", :executable?
  end
end
