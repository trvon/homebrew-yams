class YamsNightly < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage (Nightly)"
  homepage "https://github.com/trvon/yams"
  version "nightly-20260325-58a8cf8e"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/nightly-20260325-58a8cf8e/yams-nightly-20260325-58a8cf8e-macos-arm64.zip"
    sha256 "9d78b88af00d8fd767f4e21b4c71164ae5eb76745b1c8dae4ae2e67463035b88"
  else
    url "https://github.com/trvon/yams/releases/download/nightly-20260325-58a8cf8e/yams-nightly-20260325-58a8cf8e-macos-x86_64.zip"
    sha256 "60fe1e1ca659158283ea4d17acdedde724a672c00edf395389e6f135292a988a"
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

      Documentation: https://yamsmemory.ai
    EOS
  end

  test do
    assert_match(/nightly|dev/, shell_output("#{bin}/yams --version"))
    system bin/"yams", "init", "--non-interactive", "--storage", testpath/"yams-test"
    assert_path_exists testpath/"yams-test/yams.db"
  end
end
