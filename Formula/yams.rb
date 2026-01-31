class Yams < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage"
  homepage "https://github.com/trvon/yams"
  version "0.8.0"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-#{version}-macos-arm64.zip"
    sha256 "031ac62bd77de093cb976883d5f24b69a2ac3b247b46911d58726caf8a49a103"
  else
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-#{version}-macos-x86_64.zip"
    sha256 "5c01f0c5530fe1630834e6151f7366cb08d30f0d3d0a9533a7efe75a14d2fd17"
  end

  livecheck do
    url "https://github.com/trvon/yams/releases"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  def install
    root = if Dir.exist?("local/bin")
      Pathname("local")
    elsif Dir.exist?("usr/local/bin")
      Pathname("usr/local")
    elsif Dir.exist?("bin")
      Pathname(".")
    else
      odie "Could not locate install tree (expected local/bin, usr/local/bin, or bin)"
    end

    bin.install Dir[(root/"bin/*").to_s]

    # Skip spdlog to avoid conflicts with homebrew's spdlog
    (root/"include/spdlog").rmtree if (root/"include/spdlog").exist?

    include.install Dir[(root/"include/*").to_s] if (root/"include").exist?
    lib.install Dir[(root/"lib/*").to_s] if (root/"lib").exist?

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
    assert_match version.to_s, shell_output("#{bin}/yams --version")
    system "#{bin}/yams", "init", "--non-interactive", "--storage", testpath/"yams-test"
    assert_predicate testpath/"yams-test/yams.db", :exist?
    assert_predicate testpath/".config/yams/config.toml", :exist?
  end
end
