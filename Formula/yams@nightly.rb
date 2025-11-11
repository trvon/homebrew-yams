class YamsATNightly < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage (Nightly)"
  homepage "https://github.com/trvon/yams"
  version "nightly-__DATE__-__HASH__"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/__TAG__/yams-__VERSION__-macos-arm64.zip"
    sha256 "__SHA256_ARM64__"
  else
    url "https://github.com/trvon/yams/releases/download/__TAG__/yams-__VERSION__-macos-x86_64.zip"
    sha256 "__SHA256_X86_64__"
  end

  conflicts_with "yams", because: "both install the same binaries"

  def install
    # Homebrew strips the 'usr' prefix from archives
    bin.install Dir["local/bin/*"]
    
    # Skip spdlog to avoid conflicts
    (buildpath/"local/include/spdlog").rmtree if (buildpath/"local/include/spdlog").exist?
    
    include.install Dir["local/include/*"] if Dir.exist?("local/include")
    lib.install Dir["local/lib/*"] if Dir.exist?("local/lib")
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
        brew services start yams@nightly

      Documentation: https://yamsmemory.ai
    EOS
  end

  test do
    assert_match(/nightly|dev/, shell_output("#{bin}/yams --version"))
    system bin/"yams", "init", "--non-interactive", "--storage", testpath/"yams-test"
    assert_path_exists testpath/"yams-test/yams.db"
  end
end
