{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.medialine;
in
{
  options.features.extensions.medialine.enable = lib.mkEnableOption "Medialine GNOME Shell extension";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "medialine@funinkina.co.in" ];

    dconf.settings."org/gnome/shell/extensions/medialine" = {
      panel-position = "left";
      panel-index = 10;

      icon-type = "album-art";
      icon-size = 16;
      icon-spacing = 8;

      show-title = true;
      show-artist = true;
      show-album = false;
      separator = " • ";
      max-text-width = 300;
    };
  };
}
