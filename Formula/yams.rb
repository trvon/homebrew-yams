class Yams < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage"
  homepage "https://github.com/trvon/yams"
  version "0.7.10"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-#{version}-macos-arm64.zip"
    sha256 "78ef253219005a9f7b68e51b4c3538cb204e4b0dcdb3d8d9d6af6cb02d047ff2"
  else
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-#{version}-macos-x86_64.zip"
    sha256 "b9c535bd1b87e40791258a1e58cfe825deb95c7346576233468b08da8ad88369"
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
    assert_match version.to_s, shell_output("#{bin}/yams --version")
    system "#{bin}/yams", "init", "--non-interactive", "--storage", testpath/"yams-test"
    assert_predicate testpath/"yams-test/yams.db", :exist?
    assert_predicate testpath/".config/yams/config.toml", :exist?
  end
end
