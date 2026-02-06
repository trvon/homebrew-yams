class YamsNightly < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage (Nightly)"
  homepage "https://github.com/trvon/yams"
  version "nightly-20260206-e0612298"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/nightly-20260206-e0612298/yams-nightly-20260206-e0612298-macos-arm64.zip"
    sha256 "d75e8a750871d42035d6fd97c3ec536e500b95bb378f2108324a70b4f83a4f53"
  else
    url "https://github.com/trvon/yams/releases/download/nightly-20260206-e0612298/yams-nightly-20260206-e0612298-macos-x86_64.zip"
    sha256 "720d39d3c63a97b491a7175b583e4f33036e0fc977ddfe2ba886e596b264db1d"
  end

  conflicts_with "yams", because: "both install the same binaries"

  depends_on "onnxruntime"

  def install
    # Homebrew may stage archives either directly into buildpath (e.g. opt/homebrew/bin)
    # or under an extra top-level directory. Be tolerant by searching for the yams binary.
    root = if Dir.exist?("opt/homebrew/bin")
      Pathname("opt/homebrew")
    elsif Dir.exist?("local/bin")
      Pathname("local")
    elsif Dir.exist?("usr/local/bin")
      Pathname("usr/local")
    elsif Dir.exist?("bin")
      Pathname(".")
    else
      yams_exe = Dir["**/bin/yams"].first
      if yams_exe
        Pathname(yams_exe).dirname.parent
      else
        odie "Could not locate install tree (expected opt/homebrew/bin, local/bin, usr/local/bin, bin, or a directory containing bin/yams)"
      end
    end

    bin.install Dir[(root/"bin/*").to_s]

    # Skip spdlog to avoid conflicts
    (root/"include/spdlog").rmtree if (root/"include/spdlog").exist?

    include.install Dir[(root/"include/*").to_s] if (root/"include").exist?

    # Install lib contents preserving directory structure (plugins live in lib/yams/plugins/)
    if (root/"lib").exist?
      lib.install Dir[(root/"lib/*.{a,dylib,so}").to_s]
      (lib/"pkgconfig").install Dir[(root/"lib/pkgconfig/*").to_s] if (root/"lib/pkgconfig").exist?
      if (root/"lib/yams/plugins").exist?
        (lib/"yams/plugins").mkpath
        (lib/"yams/plugins").install Dir[(root/"lib/yams/plugins/*").to_s]
      end
    end

    # Remove bundled onnxruntime — Homebrew manages this dependency
    rm_f Dir[lib/"libonnxruntime*"]

    # Runtime assets (schemas, etc.)
    share.install Dir[(root/"share/*").to_s] if (root/"share").exist?
  end

  def post_install
    # Fix plugin rpaths to find Homebrew-managed onnxruntime
    Dir[lib/"yams/plugins/*.dylib"].each do |plugin|
      MachO::Tools.add_rpath(plugin, HOMEBREW_PREFIX/"lib") rescue nil
    end
  end

  service do
    run [opt_bin/"yams-daemon"]
    keep_alive true
    log_path var/"log/yams-daemon.log"
    error_log_path var/"log/yams-daemon.log"
    environment_variables YAMS_STORAGE: var/"lib/yams"
  end

  def caveats
    <<~EOS
      You have installed the nightly build of YAMS.
      This version is updated frequently and may be unstable.

      For stable releases, use: brew install trvon/yams/yams

      Initialize YAMS storage:
        yams init .

      To start the YAMS daemon as a service:
        brew services start yams-nightly

      Or (via tap alias):
        brew services start trvon/yams/yams@nightly

      Documentation: https://yamsmemory.ai
    EOS
  end

  test do
    assert_match(/nightly|dev/, shell_output("#{bin}/yams --version"))
    system bin/"yams", "init", "--non-interactive", "--storage", testpath/"yams-test"
    assert_path_exists testpath/"yams-test/yams.db"
  end
end
