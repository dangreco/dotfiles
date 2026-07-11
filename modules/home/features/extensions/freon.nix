{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.freon;
in
{
  options.features.extensions.freon.enable =
    lib.mkEnableOption "the Freon temperature-monitor GNOME Shell extension";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "freon@UshakovVasilii_Github.yahoo.com" ];

    dconf.settings."org/gnome/shell/extensions/freon" = {
      unit = 0; # centigrade
      # Just the temperature in the panel - fan RPM/voltage/power are noisy
      # for a glance-at indicator.
      show-rotationrate = false;
      show-voltage = false;
      show-power = false;
    };
  };
}
