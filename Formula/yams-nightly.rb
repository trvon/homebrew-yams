class YamsNightly < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage (Nightly)"
  homepage "https://github.com/trvon/yams"
  version "nightly-20260322-7a55178e"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/nightly-20260322-7a55178e/yams-nightly-20260322-7a55178e-macos-arm64.zip"
    sha256 "4d4a7246e2e1d1cf7c50f7c547217b93ac70c359103bbcd1023bcef7c537b52a"
  else
    url "https://github.com/trvon/yams/releases/download/nightly-20260322-7a55178e/yams-nightly-20260322-7a55178e-macos-x86_64.zip"
    sha256 "8c311040e4db58aa13d89ced91355a71fa9ba9e671cc34fecfaae5c7a1140a52"
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

    # Runtime-only Homebrew package: skip headers, pkg-config metadata, and static archives.
    # Those developer artifacts dominate keg size and are not needed for normal CLI/daemon use.
    if (root/"lib").exist?
      lib.install Dir[(root/"lib/*.{dylib,so}").to_s]
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

  service do
    run [opt_bin/"yams-daemon", "--foreground"]
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

      Documentation: https://yamsmemory.ai
    EOS
  end

  test do
    ENV["HOME"] = testpath
    assert_match(/nightly|dev/, shell_output("#{bin}/yams --version"))
    system bin/"yams", "init", "--non-interactive"
    assert_path_exists testpath/".local/share/yams/yams.db"
    assert_path_exists testpath/".config/yams/config.toml"
  end
end
