class Yams < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage"
  homepage "https://github.com/trvon/yams"
  version "0.7.7"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/v0.7.7/yams-0.7.7-macos-arm64.zip"
    sha256 "98bebc3c528e5bd7b72a57adec53134f7083fc3a2aab99ee0940b05a80236076"
  else
    url "https://github.com/trvon/yams/releases/download/v0.7.7/yams-0.7.7-macos-x86_64.zip"
    sha256 "28436124264030c3ee1d997b72afaa19104f594dc461a2b5900a1b4a991524fe"
  end

  livecheck do
    url "https://github.com/trvon/yams/releases"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  def install
    # Homebrew strips the 'usr' prefix from archives
    # So files are at local/bin, local/include, local/lib
    bin.install Dir["local/bin/*"]
    
    # Skip spdlog to avoid conflicts with homebrew's spdlog
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
    # Test that the binary was installed and can show version
    assert_match version.to_s, shell_output("#{bin}/yams --version")

    # Test basic functionality - init in a temp directory
    system bin/"yams", "init", "--non-interactive", "--storage", testpath/"yams-test"
    assert_path_exists testpath/"yams-test/yams.db"
    assert_path_exists testpath/".config/yams/config.toml"
  end
end
