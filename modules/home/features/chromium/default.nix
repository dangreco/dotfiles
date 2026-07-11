{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.chromium;
in
{
  options.features.chromium.enable = lib.mkEnableOption "Chromium";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = with pkgs; [
      ungoogled-chromium
    ];
  };
}
