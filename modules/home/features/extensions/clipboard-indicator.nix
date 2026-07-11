{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.clipboard-indicator;
in
{
  options.features.extensions.clipboard-indicator.enable =
    lib.mkEnableOption "the Clipboard Indicator GNOME Shell extension";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "clipboard-indicator@tudmotu.com" ];

    dconf.settings."org/gnome/shell/extensions/clipboard-indicator" = {
      history-size = 50; # upstream default (15) is thin for a history picker
      move-item-first = true; # selecting an entry bumps it to the top, like most clipboard managers
      display-mode = 0;
      enable-keybindings = false;
      show-settings-button = false;
      show-private-mode = false;
      show-clear-history-button = false;
    };
  };
}
