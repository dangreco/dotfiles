{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.features.homebrew;
in
{
  # Always import the module so `homebrew.*` options exist whenever an app feature
  # (slack/spotify/bitwarden/chromium) appends to homebrew.casks. Mirrors the flatpak
  # base feature. The module's `homebrew.enable` defaults to *true*, so importing it
  # alone would activate it everywhere — the `config` below forces it off unless we're
  # on darwin *and* an app opted in, which also keeps it from touching Linux (where it
  # would otherwise try to install linuxbrew).
  imports = [ inputs.home-manager-brew.homeManagerModules.default ];

  options.features.homebrew.enable = lib.mkEnableOption "declarative Homebrew cask management (macOS, standalone home-manager)";

  config = {
    # Normal-priority assignment overrides the module's `default = true`, so no mkForce
    # is needed. Off on Linux and off until an app feature enables it.
    homebrew.enable = cfg.enable && pkgs.stdenv.isDarwin;

    # Never delete brew apps the user installed by hand (default runs
    # `brew bundle cleanup --force`), and don't `brew upgrade --greedy` every activation.
    homebrew.cleanup = false;
    homebrew.upgrade = false;

    # Put brew on PATH in fish (the shell this config uses).
    homebrew.enableShellIntegration = true;
  };
}
