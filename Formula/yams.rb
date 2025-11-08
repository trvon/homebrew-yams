class Yams < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage"
  homepage "https://github.com/trvon/yams"
  version "0.7.7"
  license "GPL-3.0-or-later"

  on_arm do
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-#{version}-macos-arm64.zip"
    sha256 "98bebc3c528e5bd7b72a57adec53134f7083fc3a2aab99ee0940b05a80236076"
  end

  on_intel do
    url "https://github.com/trvon/yams/releases/download/v#{version}/yams-#{version}-macos-x86_64.zip"
    sha256 "28436124264030c3ee1d997b72afaa19104f594dc461a2b5900a1b4a991524fe"
  end

  livecheck do
    url "https://github.com/trvon/yams/releases"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  def install
    # Pre-built binaries are extracted to usr/local/
    # Copy binaries
    (buildpath/"usr/local/bin").glob("*").each do |f|
      bin.install f
    end
    
    # Copy includes if present
    if (buildpath/"usr/local/include").exist?
      (buildpath/"usr/local/include").glob("*").each do |f|
        include.install f
      end
    end
    
    # Copy libraries if present
    if (buildpath/"usr/local/lib").exist?
      (buildpath/"usr/local/lib").glob("*").each do |f|
        lib.install f
      end
    end
  end

  def caveats
    <<~EOS
      To initialize YAMS storage:
        yams init --non-interactive

      For custom storage location:
        export YAMS_STORAGE="$HOME/.local/share/yams"
        yams init --non-interactive

      Documentation and examples:
        https://github.com/trvon/yams/tree/main/docs
    EOS
  end

  test do
    # Test that the binary was installed and can show version
    assert_match version.to_s, shell_output("#{bin}/yams --version")
    
    # Test basic functionality - init in a temp directory
    system "#{bin}/yams", "init", "--non-interactive", "--storage", testpath/"yams-test"
    assert_predicate testpath/"yams-test/yams.db", :exist?
    assert_predicate testpath/".config/yams/config.toml", :exist?
  end
end