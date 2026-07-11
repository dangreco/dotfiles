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
  imports = [ ./adwaita.nix ];
  options.features.zed = {
    enable = lib.mkEnableOption "the Zed code editor (native self-updating install)";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra entries merged into Zed's global settings.json";
    };
  };

  # systemd.user is Linux-only; darwin (launchd, mirroring the `update` feature's
  # split) is intentionally out of scope for now.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    programs.zed-editor = {
      enable = true;
      package = null; # installed + kept updated by Zed's own installer, not Nix
      userSettings = lib.recursiveUpdate {
        auto_update = true;
        # Align Zed's chrome with Adwaita where the editor allows it: the UI font
        # becomes GNOME's Cantarell, and text selection is rectangular (GTK's
        # selection isn't rounded). Zed's theme is color-only - element radii,
        # padding and margins aren't exposed (hardcoded in the renderer) - so the
        # Adwaita radius/spacing scale (9/12/15px) can't be applied here.
        ui_font_family = "Cantarell";
        rounded_selection = false;
        # Track the desktop color scheme (GNOME light/dark) via the bundled theme.
        theme = {
          mode = "system";
          light = "Adwaita Light";
          dark = "Adwaita Dark";
        };

        telemetry = {
          diagnostics = false;
          metrics= false;
          anthropic_retention= false;
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

        agent =  {
          button = false;
          dock = "right";
        };
      } cfg.settings;
    };

    # install.sh symlinks the binary to ~/.local/bin/zed.
    home.sessionPath = [ "$HOME/.local/bin" ];

    systemd.user.services.zed-install = {
      Unit.Description = "Install the Zed editor (zed.dev/install.sh)";
      Service = {
        Type = "oneshot";
        ExecStart = "${installScript}/bin/zed-install";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
