{ config, lib, ... }:
let
  cfg = config.features.fish;
in
{
  options.features.fish = {
    enable = lib.mkEnableOption "fish";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      # Disable the startup greeting.
      interactiveShellInit = "set -g fish_greeting";
    };
  };
}
