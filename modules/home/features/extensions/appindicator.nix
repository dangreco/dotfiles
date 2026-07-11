{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.appindicator;
in
{
  options.features.extensions.appindicator.enable =
    lib.mkEnableOption "the AppIndicator/KStatusNotifierItem GNOME Shell extension";

  # Restores the legacy system tray so apps that only ship a tray icon (no
  # native GNOME integration) still show up in the top bar.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "appindicatorsupport@rgcjonas.gmail.com" ];
    # Upstream defaults (right-aligned tray, auto icon size) are already
    # sensible - no overrides needed.
  };
}
