class Yams < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage"
  homepage "https://github.com/trvon/yams"
  version "0.12.1"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-0.12.1-macos-arm64.zip"
    sha256 "31df9053d954a1b83f9145eea5f0ab6fc36b206ff8a5e0ac3545c840faa34f0b"
  else
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-0.12.1-macos-x86_64.zip"
    sha256 "55e53da189cdec3aafa1de49bc0260f160abe846649e92390cda3d2010dea5a0"
  end

  depends_on "onnxruntime"

  livecheck do
    url "https://github.com/trvon/yams/releases"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

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
      Initialize YAMS storage:
        yams init .

      Or specify custom location:
        export YAMS_STORAGE="$HOME/.local/share/yams"
        yams init

      To start the YAMS daemon as a service:
        brew services start yams
      
      To stop the daemon:
        brew services stop yams

      Documentation: https://yamsmemory.ai
      Repository: https://github.com/trvon/yams
    EOS
  end

  test do
    ENV["HOME"] = testpath
    assert_match version.to_s, shell_output("#{bin}/yams --version")
    system "#{bin}/yams", "init", "--non-interactive"
    assert_predicate testpath/".local/share/yams/yams.db", :exist?
    assert_predicate testpath/".config/yams/config.toml", :exist?
  end
end
