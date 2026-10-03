class YamsNightly < Formula
  desc "Yet Another Memory System - High-performance content-addressed storage (Nightly)"
  homepage "https://github.com/trvon/yams"
  version "nightly-20261003-8dd0ef1c"
  license "GPL-3.0-or-later"

  if Hardware::CPU.arm?
    url "https://github.com/trvon/yams/releases/download/experimental-nightly-20261003-8dd0ef1c337a3dcb1ef8e937d0e81cf5691fb620/yams-nightly-20261003-8dd0ef1c-macos-arm64.zip"
    sha256 "203563020b31df77353c0244b2a2dfd0dd1eed59e3d55a2189f7638e7ce70811"
  else
    url "https://github.com/trvon/yams/releases/download/experimental-nightly-20261003-8dd0ef1c337a3dcb1ef8e937d0e81cf5691fb620/yams-nightly-20261003-8dd0ef1c-macos-x86_64.zip"
    sha256 "c7429f450dd03c500fa059d517a108f1b719f4b13a887d880b588d49199a7366"
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
      # Private runtime libraries (ONNX resource registry) live in lib/yams and are
      # found through @loader_path / @executable_path RUNPATHs.
      (lib/"yams").install Dir[(root/"lib/yams/*.{dylib,so}").to_s]
      if (root/"lib/yams/plugins").exist?
        (lib/"yams/plugins").mkpath
        (lib/"yams/plugins").install Dir[(root/"lib/yams/plugins/*").to_s]
      end
    end

    # The formula depends on Homebrew's onnxruntime, which the plugins prefer over
    # the private fallback copy the archive carries in lib/yams/onnxruntime; do not
    # install that copy (or stray copies from older archive layouts).
    rm_f Dir[lib/"libonnxruntime*"]
    rm_f Dir[lib/"yams/libonnxruntime*"]
    rm_rf lib/"yams/onnxruntime"

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
