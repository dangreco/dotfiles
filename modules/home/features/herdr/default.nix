{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.herdr;

  # herdr has no self-updater: install.sh always fetches the latest release
  # (herdr.dev/latest.json) and overwrites the binary, so re-running it upgrades in
  # place. Unlike the Zed bootstrap (install once, Zed updates itself), we run this
  # on a timer to keep herdr current — see the units below.
  updateScript = pkgs.writeShellApplication {
    name = "herdr-update";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      export HERDR_INSTALL_DIR="$HOME/.local/bin"
      curl -fsSL https://herdr.dev/install.sh | sh
    '';
  };
in
{
  options.features.herdr.enable = lib.mkEnableOption "herdr, a terminal agent multiplexer (self-updating binary)";

  # install.sh installs the binary into ~/.local/bin on both platforms; only the
  # scheduler differs (systemd on Linux, launchd on darwin — mirroring the `update`
  # and `zed` features).
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.sessionPath = [ "$HOME/.local/bin" ];
      }

      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.herdr-update = {
          Unit.Description = "Install/update herdr (herdr.dev/install.sh)";
          Service = {
            Type = "oneshot";
            ExecStart = "${updateScript}/bin/herdr-update";
          };
        };

        systemd.user.timers.herdr-update = {
          Unit.Description = "Periodically update herdr to the latest release";
          Timer = {
            OnStartupSec = "5min"; # fresh install shortly after login
            OnUnitActiveSec = "24h"; # then daily
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents.herdr-update = {
          enable = true;
          config = {
            ProgramArguments = [ "${updateScript}/bin/herdr-update" ];
            RunAtLoad = true; # install/update at login
            StartInterval = 86400; # then daily
          };
        };
      })
    ]
  );
}
