{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.gimp;
in
{
  options.features.gimp.enable = lib.mkEnableOption "GIMP image editor (Flatpak)";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.flatpak.enable = true; # pull in the base plumbing (bools merge cleanly)
    services.flatpak.packages = [ "org.gimp.GIMP" ];
  };
}
