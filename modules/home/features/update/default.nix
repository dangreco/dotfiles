{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.features.update;

  selfRev = inputs.self.rev or "";
  system = pkgs.stdenv.hostPlatform.system;
  stateDir = "${config.xdg.stateHome}/dotfiles";
  url = "https://github.com/${cfg.repo}.git";
  flake = "github:${cfg.repo}";

  checkScript = pkgs.writeShellApplication {
    name = "dotfiles-update-check";
    runtimeInputs = [
      pkgs.git
      pkgs.coreutils
      pkgs.gnused
      pkgs.gawk
    ];
    text = ''
      INSTALLED_REV="${selfRev}"
      [ -n "$INSTALLED_REV" ] || exit 0

      url="${url}"

      remote=$(git ls-remote "$url" "refs/heads/${cfg.branch}" | cut -f1) || exit 0
      [ -n "$remote" ] || exit 0

      # Strip the peeled ^{} suffix so an annotated tag maps to its commit SHA;
      # the peeled entry sorts right after the tag-object entry, so last-wins.
      tags=$(git ls-remote --tags "$url" | sed -E 's#\^\{\}##') || tags=""

      tag_for() {
        awk -v sha="$1" '$1 == sha { t = $2; sub(/^refs\/tags\//, "", t); print t; exit }' <<<"$tags"
      }

      version_of() {
        local t
        t=$(tag_for "$1")
        if [ -n "$t" ]; then
          printf '%s\n' "$t"
        else
          printf '%s\n' "''${1:0:7}"
        fi
      }

      mkdir -p "${stateDir}"
      if [ "$remote" != "$INSTALLED_REV" ]; then
        printf '%s\n%s\n' \
          "$(version_of "$INSTALLED_REV")" \
          "$(version_of "$remote")" \
          > "${stateDir}/update-available"
      else
        rm -f "${stateDir}/update-available" "${stateDir}/snooze"
      fi
    '';
  };

  updateScript = pkgs.writeShellApplication {
    name = "dotfiles-update";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      home-manager switch --refresh --flake "${flake}#${cfg.profile}@${system}"
      rm -f "${stateDir}/update-available" "${stateDir}/snooze"
    '';
  };

  fishPrompt = ''
    if status is-interactive; and isatty stdin
      set -l flag "${stateDir}/update-available"
      set -l snooze "${stateDir}/snooze"
      if test -f $flag
        set -l now (date +%s)
        set -l show 1
        if test -f $snooze
          read -l until <$snooze
          test "$now" -lt "$until"; and set show 0
        end
        if test $show -eq 1
          set -l ver (cat $flag)
          set_color blue; echo -n ":: "; set_color normal
          echo "dotfiles update available ($ver[1] → $ver[2])."
          read -l -P "Update now? [y/N] " ans
          if test "$ans" = y -o "$ans" = Y
            dotfiles-update
          else
            math "$now + 21600" >$snooze
          end
        end
      end
    end
  '';
in
{
  options.features.update = {
    enable = lib.mkEnableOption "background update checks";

    repo = lib.mkOption {
      type = lib.types.str;
      default = "dangreco/dotfiles";
      description = "GitHub `owner/repo` checked for newer commits.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Branch to compare the installed revision against.";
    };

    profile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Flake profile key (e.g. `dan`/`work`) switched to on update.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [ updateScript ];

        assertions = [
          {
            assertion = cfg.profile != null;
            message = "features.update.profile must be set when update checks are enabled.";
          }
        ];
      }

      (lib.mkIf config.features.fish.enable {
        programs.fish.interactiveShellInit = fishPrompt;
      })

      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.dotfiles-update-check = {
          Unit.Description = "Check for dotfiles updates";
          Service = {
            Type = "oneshot";
            ExecStart = "${checkScript}/bin/dotfiles-update-check";
          };
        };

        systemd.user.timers.dotfiles-update-check = {
          Unit.Description = "Periodically check for dotfiles updates";
          Timer = {
            OnStartupSec = "5min";
            OnUnitActiveSec = "6h";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents.dotfiles-update-check = {
          enable = true;
          config = {
            ProgramArguments = [ "${checkScript}/bin/dotfiles-update-check" ];
            StartInterval = 21600;
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
