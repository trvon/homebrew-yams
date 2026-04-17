class YamsNightly < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage (Nightly)"
  homepage "https://github.com/trvon/yams"
  version "nightly-20260417-bd20aee2"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/nightly-20260417-bd20aee2/yams-nightly-20260417-bd20aee2-macos-arm64.zip"
    sha256 "76f01e08fa22c0b6ebde9a672c54d7b01f7fefa3bd67aa5c4926f4d81faa532a"
  else
    url "https://github.com/trvon/yams/releases/download/nightly-20260417-bd20aee2/yams-nightly-20260417-bd20aee2-macos-x86_64.zip"
    sha256 "cf3733a25cf80ee7524c586fe566e6f9ed9953c1732df18efa234c0503a8e43f"
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

    generate_completions_from_executable(bin/"yams", "completion") if (bin/"yams").exist?
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

      Homebrew installs completion files for bash, zsh, and fish.
      If completion is not active in your current shell yet, start a new shell or use:
        source <(yams completion bash)
        autoload -U compinit && compinit && source <(yams completion zsh)
        mkdir -p ~/.config/fish/completions && yams completion fish > ~/.config/fish/completions/yams.fish

      Zsh persistent setup:
        mkdir -p ~/.local/share/zsh/site-functions
        yams completion zsh > ~/.local/share/zsh/site-functions/_yams
        # Ensure ~/.local/share/zsh/site-functions is on fpath before compinit
        # then run: autoload -U compinit && compinit

      Nested subcommands are included, e.g.:
        yams config embeddings <TAB>
        yams plugin trust <TAB>
        yams plugins trust <TAB>
        yams daemon start --log-level <TAB>
        yams config search path-tree enable --mode <TAB>

      PowerShell completion is available manually:
        pwsh -NoLogo -NoProfile -Command 'Invoke-Expression (yams completion powershell | Out-String)'

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
