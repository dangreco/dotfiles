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
    programs.git = {
      enable = true;
      lfs.enable = cfg.lfs.enable;

      # Syntax-highlighted diffs.
      delta = {
        enable = true;
        options.navigate = true;
      };

      userName = lib.mkIf (cfg.userName != null) cfg.userName;
      userEmail = lib.mkIf (cfg.userEmail != null) cfg.userEmail;
    };
  };
}
