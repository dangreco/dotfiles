{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.slack;
in
{
  options.features.slack.enable = lib.mkEnableOption "Slack (Flatpak)";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.flatpak.enable = true; # pull in the base plumbing (bools merge cleanly)
    services.flatpak.packages = [ "com.slack.Slack" ];
  };
}
