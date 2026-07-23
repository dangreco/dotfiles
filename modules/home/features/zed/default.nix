{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.zed;

  # Zed manages its own binary + auto-updates itself once installed (that's the whole
  # point of using zed.dev/install.sh instead of nixpkgs' zed-editor, which hardcodes
  # ZED_UPDATE_EXPLANATION and disables the native updater). This only bootstraps the
  # initial install so we don't re-invoke the network installer on every login.
  installScript = pkgs.writeShellApplication {
    name = "zed-install";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      if [ ! -x "$HOME/.local/bin/zed" ]; then
        curl -f https://zed.dev/install.sh | sh
      fi
    '';
  };
in
{
  options.features.zed = {
    enable = lib.mkEnableOption "the Zed code editor (native self-updating install)";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra entries merged into Zed's global settings.json";
    };
  };

  # Settings + the install bootstrap are cross-platform; only the service that runs
  # the bootstrap differs (systemd on Linux, launchd on darwin — mirroring the
  # `update` feature's split). Zed reads ~/.config/zed/settings.json on both.
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.zed-editor = {
          enable = true;
          package = null; # installed + kept updated by Zed's own installer, not Nix
          userSettings = lib.recursiveUpdate {
            auto_update = true;
            ui_font_family = "Inter";
            buffer_font_family = "JetBrains Mono";
            rounded_selection = false;

            icon_theme = "Catppuccin Latte";
            theme = {
              mode = "system";
              light = "Catppuccin Latte";
              dark = "Catppuccin Mocha";
            };

            cursor_shape = "bar";
            load_direnv = "direct";
            format_on_save = "on";

            title_bar = {
              show_onboarding_banner = false;
              show_user_picture = false;
              show_sign_in = false;
            };

            telemetry = {
              diagnostics = false;
              metrics = false;
              anthropic_retention = false;
            };

            auto_install_extensions = {
              html = true;
              nix = true;
              toml = true;
              catppuccin = true;
              catppuccin-icons = true;
            };

            project_panel = {
              button = true;
              dock = "left";
              starts_open = true;
            };

            git_panel = {
              button = true;
              dock = "left";
            };

            outline_panel = {
              button = true;
              dock = "left";
            };

            debugger = {
              button = true;
              dock = "bottom";
            };

            terminal = {
              button = true;
              dock = "bottom";

            };

            collaboration_panel = {
              button = false;
              dock = "right";
            };

            agent = {
              button = false;
              dock = "right";
            };
          } cfg.settings;
        };

        # install.sh symlinks the binary to ~/.local/bin/zed.
        home.sessionPath = [ "$HOME/.local/bin" ];
      }

      (lib.mkIf pkgs.stdenv.isLinux {
        fonts.fontconfig.enable = true;
        home.packages = with pkgs; [
          inter
          jetbrains-mono
        ];

        systemd.user.services.zed-install = {
          Unit.Description = "Install the Zed editor (zed.dev/install.sh)";
          Service = {
            Type = "oneshot";
            ExecStart = "${installScript}/bin/zed-install";
          };
          Install.WantedBy = [ "default.target" ];
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        # Bootstrap Zed via launchd (mirrors the `update` feature's darwin split).
        launchd.agents.zed-install = {
          enable = true;
          config = {
            ProgramArguments = [ "${installScript}/bin/zed-install" ];
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
