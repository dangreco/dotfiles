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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # ungoogled-chromium has no darwin build in nixpkgs; on macOS it comes as a cask.
      (lib.mkIf pkgs.stdenv.isLinux {
        home.packages = with pkgs; [
          ungoogled-chromium
        ];
      })
      (lib.mkIf pkgs.stdenv.isDarwin {
        features.homebrew.enable = true;
        homebrew.casks = [ "ungoogled-chromium" ];
      })
    ]
  );
}
