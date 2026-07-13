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
      interactiveShellInit = ''
        set -g fish_greeting
        if test -f $HOME/.config/fish/config.local.fish
          source $HOME/.config/fish/config.local.fish
        end
      '';
      shellInit = ''
        if test -f /nix/var/nix/profiles/default/etc/profile.d/nix.fish
          source /nix/var/nix/profiles/default/etc/profile.d/nix.fish
        end
      '';
    };
  };
}
