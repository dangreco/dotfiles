{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.tophat;
in
{
  options.features.extensions.tophat.enable =
    lib.mkEnableOption "the TopHat system-monitor GNOME Shell extension";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "tophat@fflewddur.github.io" ];

    dconf.settings."org/gnome/shell/extensions/tophat" = {
      show-cpu = true;
      show-mem = true;

      cpu-show-cores = false; # one aggregate CPU meter instead of one bar per core

      # hide
      show-disk = false;
      show-fs = false;
      show-net = false;
    };
  };
}
