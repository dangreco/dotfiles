{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.caffeine;
in
{
  options.features.extensions.caffeine.enable =
    lib.mkEnableOption "the Caffeine GNOME Shell extension";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "caffeine@patapon.info" ];

    dconf.settings."org/gnome/shell/extensions/caffeine" = {
      enable-fullscreen = true; # auto-inhibit suspend while a fullscreen app is running
      show-notifications = false; # skip the toast every time it toggles
      restore-state = true; # remember the on/off state across shell restarts (default forgets it)
    };
  };
}
