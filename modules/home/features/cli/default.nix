{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.cli;
in
{
  options.features.cli.enable = lib.mkEnableOption "modern CLI tools";

  config = lib.mkIf cfg.enable {
    # eza: ls replacement. Shell integration is on by default, so it adds the
    # ls/ll/la/lt aliases in any enabled shell (e.g. fish).
    programs.eza = {
      enable = true;
      icons = "never";
      git = true;
    };

    programs.fd.enable = true; # `find` replacement
    programs.fastfetch.enable = true; # system info
    programs.ripgrep.enable = true; # `grep` replacement (rg)
    programs.bat.enable = true; # `cat` with syntax highlighting
    programs.btop.enable = true; # resource monitor
    programs.jq.enable = true; # JSON processor
    programs.lazygit.enable = true; # git TUI
    programs.tealdeer.enable = true; # `tldr` quick command examples
    programs.yazi.enable = true; # terminal file manager

    home.packages = with pkgs; [
      dust # `du` replacement
      procs # `ps` replacement
      hyperfine # command benchmarking
      gping # `ping` with a graph
      doggo # modern `dig`
    ];
  };
}
