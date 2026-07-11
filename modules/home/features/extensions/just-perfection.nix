{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.just-perfection;
in
{
  options.features.extensions.just-perfection.enable =
    lib.mkEnableOption "the Just Perfection GNOME Shell tweak extension";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "just-perfection-desktop@just-perfection" ];

    dconf.settings."org/gnome/shell/extensions/just-perfection" = {
      animation = 4; # faster
      startup-status = 0; # boot to the desktop, not the overview (upstream default)
      workspace-wrap-around = true; # cycling workspaces wraps instead of stopping at the ends
    };
  };
}
