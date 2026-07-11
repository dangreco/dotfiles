{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.dejadup;
in
{
  options.features.dejadup.enable = lib.mkEnableOption "Déjà Dup backup tool (Flatpak)";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.flatpak.enable = true; # pull in the base plumbing (bools merge cleanly)
    services.flatpak.packages = [ "org.gnome.DejaDup" ];
  };
}
