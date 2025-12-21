class YamsATNightly < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage (Nightly)"
  homepage "https://github.com/trvon/yams"
  version "nightly-20251203-d2a2196"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/nightly-20251203-d2a2196/yams-nightly-20251203-069c911-macos-arm64.zip"
    sha256 "507ff57b8139daf08ebbf2e36ebb024c1a3819e7c8375b30ce922c02374fa35a"
  else
    url "https://github.com/trvon/yams/releases/download/nightly-20251203-d2a2196/yams-nightly-20251203-069c911-macos-x86_64.zip"
    sha256 "8e821080dd098d149f06c1d7b3e67a17a4f6f1866815211aac706b36f55e458c"
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
