{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.bitwarden;
in
{
  options.features.bitwarden.enable = lib.mkEnableOption "Bitwarden";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = with pkgs; [
      bitwarden-cli
      bitwarden-desktop
    ];
  };
}
