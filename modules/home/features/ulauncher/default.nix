{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.ulauncher;
in
{
  options.features.ulauncher.enable = lib.mkEnableOption "the Ulauncher application launcher";

  # Ulauncher is Linux/GTK-only; on darwin this whole feature is a no-op.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.ulauncher ];

    # Run Ulauncher as a hidden daemon from login so the Super+s shortcut (which
    # calls `ulauncher-toggle`) just signals the running process — no cold-start
    # delay on first invocation. The `dconf` feature owns that keybinding.
    systemd.user.services.ulauncher = {
      Unit = {
        Description = "Ulauncher application launcher";
        Documentation = "https://ulauncher.io";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window --no-window-shadow";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
