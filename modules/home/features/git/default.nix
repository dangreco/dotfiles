{ config, lib, ... }:
let
  cfg = config.features.git;
in
{
  options.features.git = {
    enable = lib.mkEnableOption "git";

    userName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git user name (`user.name`).";
    };

    userEmail = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Git user email (`user.email`).";
    };

    lfs.enable = lib.mkEnableOption "git-lfs";
  };

  config = lib.mkIf cfg.enable {
    programs.gh.enable = true;
    programs.git = {
      enable = true;
      lfs.enable = cfg.lfs.enable;

      settings.user = {
        name = lib.mkIf (cfg.userName != null) cfg.userName;
        email = lib.mkIf (cfg.userEmail != null) cfg.userEmail;
      };
    };

    # Syntax-highlighted diffs.
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options.navigate = true;
    };
  };
}
