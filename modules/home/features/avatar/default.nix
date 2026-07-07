{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.avatar;

  stateDir = "${config.xdg.stateHome}/dotfiles";

  avatarScript = pkgs.writeShellApplication {
    name = "set-github-avatar";
    runtimeInputs = [
      pkgs.curl
      pkgs.coreutils
      pkgs.gawk
      pkgs.systemd # busctl
    ];
    text = ''
      stateDir="${stateDir}"
      avatar="$stateDir/avatar.png"
      user="$(id -un)"

      mkdir -p "$stateDir"

      # Download to a temp file, then atomically move into place.
      curl -fsSL -o "$avatar.tmp" \
        "https://github.com/${cfg.username}.png?size=${toString cfg.size}"
      mv -f "$avatar.tmp" "$avatar"

      # Resolve this user's AccountsService object path, then set the icon.
      # SetIconFile makes the root accounts-daemon copy the file into
      # /var/lib/AccountsService/icons/$user. The polkit action
      # org.freedesktop.accounts.change-own-user-data allows this without a
      # session or agent, so the timer can set the avatar unattended.
      obj="$(busctl --system call org.freedesktop.Accounts /org/freedesktop/Accounts \
        org.freedesktop.Accounts FindUserByName s "$user" | awk '{print $2}' | tr -d '"')"
      busctl --system call org.freedesktop.Accounts "$obj" \
        org.freedesktop.Accounts.User SetIconFile s "$avatar"
    '';
  };
in
{
  options.features.avatar = {
    enable = lib.mkEnableOption "syncing the GitHub profile picture to the user avatar";

    username = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "GitHub username whose profile picture (`github.com/<username>.png`) is used.";
    };

    size = lib.mkOption {
      type = lib.types.int;
      default = 512;
      description = "Pixel size requested from GitHub (the `?size=` query parameter).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ avatarScript ];

        assertions = [
          {
            assertion = cfg.username != "";
            message = "features.avatar.username must be set when the avatar sync is enabled.";
          }
        ];
      }

      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.set-github-avatar = {
          Unit.Description = "Sync GitHub profile picture to user avatar";
          Service = {
            Type = "oneshot";
            ExecStart = "${avatarScript}/bin/set-github-avatar";
          };
        };

        systemd.user.timers.set-github-avatar = {
          Unit.Description = "Periodically sync GitHub profile picture to user avatar";
          Timer = {
            OnStartupSec = "2min";
            OnUnitActiveSec = "1d";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      })
    ]
  );
}
