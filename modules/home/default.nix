{ lib, pkgs, ... }:
{
  imports = [ ./features ];

  programs.home-manager.enable = true;

  # Set to the release first activated against; don't bump it after that.
  home.stateVersion = lib.mkDefault "25.11";

  # vim as the default editor everywhere.
  home.packages = [ pkgs.vim ];
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };
}
