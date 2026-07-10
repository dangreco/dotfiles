{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.features.ulauncher;

  userThemes = "${config.xdg.configHome}/ulauncher/user-themes";
  settings = "${config.xdg.configHome}/ulauncher/settings.json";

  # Appended to each variant's theme.css so the launcher floats above the
  # desktop and stands out — but in GNOME's own idiom, not a macOS look: the
  # same layered elevation GNOME gives its menus/dialogs (a crisp 1px CSD-style
  # ring + a tight contact shadow + a soft ambient shadow), replacing upstream's
  # near-invisible shadow. Radius/colors are left as the GNOME theme ships them.
  # The shadow only renders because we (a) keep Ulauncher's window shadow (see
  # the service below) and (b) give `.app` a positive margin here, so there's a
  # transparent gutter for it instead of it being clipped to the window edge.
  themeOverrideCss = ''

    /* dotfiles: GNOME-style elevation so the launcher stands out. */
    .app {
        /* Positive margin shrinks the panel inside a larger transparent window
           so the shadow below has room to render instead of being clipped to
           the window edge (upstream uses a negative margin, leaving none). */
        margin: 24px;
        box-shadow:
            0 0 0 1px rgba(0, 0, 0, 0.22),
            0 3px 8px 0 rgba(0, 0, 0, 0.20),
            0 8px 20px 2px rgba(0, 0, 0, 0.28);
    }
  '';

  # Reinstall both theme variants from the pinned store copy and bake the GNOME
  # accent + color scheme into them, then bounce Ulauncher. Replaces upstream's
  # install.py/accent-color.py — no runtime git clone, no Python. Idempotent:
  # every run rebuilds from the read-only store source, so it can't drift.
  themeApply = pkgs.writeShellApplication {
    name = "ulauncher-theme-apply";
    runtimeInputs = [
      pkgs.dconf # dconf read
      pkgs.jq
      pkgs.gnused
      pkgs.coreutils
      pkgs.systemd # systemctl
    ];
    text = ''
            userThemes="${userThemes}"
            settings="${settings}"
            src="${inputs.ulauncher-theme-gnome}"

            # Read GNOME settings with `dconf`, not `gsettings`: the nixpkgs gsettings
            # can't load the host's dconf GIO module, so it silently falls back to the
            # in-memory backend and returns schema defaults instead of the live values.
            # `dconf` talks to the dconf service over D-Bus directly, so it's accurate.
            # It prints values GVariant-quoted ('blue') and nothing for an unset key.

            # GNOME accent name -> hex (mirrors accent-color.py). Blue is the GNOME
            # default and the fallback for unknown/unset values, including GNOME < 47
            # where the accent-color key doesn't exist.
            accent="$(dconf read /org/gnome/desktop/interface/accent-color 2>/dev/null | tr -d "'")"
            [ -n "$accent" ] || accent=blue
            case "$accent" in
              teal) hex="#2190a4" ;;
              green) hex="#3a944a" ;;
              yellow) hex="#c88800" ;;
              orange) hex="#ed5b00" ;;
              red) hex="#e62d42" ;;
              pink) hex="#d56199" ;;
              purple) hex="#9141ac" ;;
              slate) hex="#6f8396" ;;
              *) hex="#3584e4" ;;
            esac

            # Stop Ulauncher before touching its config: it loads settings.json into
            # memory at startup and flushes that copy back on shutdown, so restarting
            # it *after* editing would clobber the theme-name we write below with the
            # old value. Stop first, edit, then start fresh so it reads the new theme.
            wasActive="$(systemctl --user is-active ulauncher.service || true)"
            if [ "$wasActive" = active ]; then
              systemctl --user stop ulauncher.service || true
            fi

            # Refresh both variants from the store (--no-preserve=mode strips the
            # read-only store perms so the accent edits below can write), then bake in
            # the accent color two ways: selected_bg_color in theme.css (theme-gtk-3.20
            # @imports it, so modern GTK is covered) and matched_text_hl_colors in the
            # manifest.
            mkdir -p "$userThemes"
            for variant in light dark; do
              name="ulauncher-theme-gnome-$variant"
              dest="$userThemes/$name"
              rm -rf "$dest"
              cp -rL --no-preserve=mode,ownership "$src/$name" "$dest"
              sed -i -E "s/@define-color selected_bg_color #[0-9a-fA-F]{6};/@define-color selected_bg_color $hex;/" "$dest/theme.css"
              tmp="$(mktemp)"
              jq --arg c "$hex" '.matched_text_hl_colors.when_selected=$c | .matched_text_hl_colors.when_not_selected=$c' "$dest/manifest.json" >"$tmp"
              mv -f "$tmp" "$dest/manifest.json"
              # Layer our GNOME-style elevation on top of upstream's .app rule (last
              # rule of equal specificity wins for box-shadow). Quoted heredoc: the
              # CSS is emitted verbatim, no shell expansion.
              cat >>"$dest/theme.css" <<'ULAUNCHER_THEME_OVERRIDE'
      ${themeOverrideCss}
      ULAUNCHER_THEME_OVERRIDE
            done

            # Pick light/dark from the color scheme and write it into Ulauncher's
            # settings (create the file if Ulauncher hasn't written one yet).
            scheme="$(dconf read /org/gnome/desktop/interface/color-scheme 2>/dev/null | tr -d "'")"
            if [ "$scheme" = "prefer-dark" ]; then
              theme="ulauncher-theme-gnome-dark"
            else
              theme="ulauncher-theme-gnome-light"
            fi
            mkdir -p "$(dirname "$settings")"
            tmp="$(mktemp)"
            if [ -f "$settings" ]; then
              jq --arg t "$theme" '.["theme-name"]=$t' "$settings" >"$tmp"
            else
              jq -n --arg t "$theme" '{"theme-name":$t}' >"$tmp"
            fi
            mv -f "$tmp" "$settings"

            # Start Ulauncher again if we stopped it, so it reads the new theme +
            # settings. The window is hidden, so this is invisible.
            if [ "$wasActive" = active ]; then
              systemctl --user start ulauncher.service || true
            fi
    '';
  };

  # Apply once at startup (initial install / login-time correctness), then
  # reapply whenever the color scheme or accent color changes. Both keys live in
  # org.gnome.desktop.interface, so a single monitor covers them.
  themeWatch = pkgs.writeShellApplication {
    name = "ulauncher-theme-watch";
    runtimeInputs = [
      pkgs.dconf # dconf watch
      themeApply
    ];
    text = ''
      ulauncher-theme-apply || true
      # `dconf watch` prints the changed key's full path on its own line (then an
      # indented value line); react when either key we care about changes.
      dconf watch /org/gnome/desktop/interface/ | while read -r line; do
        case "$line" in
          */color-scheme | */accent-color) ulauncher-theme-apply || true ;;
        esac
      done
    '';
  };
in
{
  options.features.ulauncher.enable = lib.mkEnableOption "the Ulauncher application launcher";

  # Ulauncher is Linux/GTK-only; on darwin this whole feature is a no-op.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    # `ulauncher-toggle` (bound to Super+s via dconf) shells out to a bare
    # `dbus-send`, which nixpkgs doesn't wrap into its PATH — provide it so the
    # shortcut works on non-NixOS where dbus tools aren't globally installed.
    home.packages = [
      pkgs.ulauncher
      pkgs.dbus
      themeApply
    ];

    # Run Ulauncher as a hidden daemon from login so the Super+s shortcut (which
    # calls `ulauncher-toggle`) just signals the running process — no cold-start
    # delay on first invocation. The `dconf` feature owns that keybinding.
    #
    # We deliberately do NOT pass `--no-window-shadow`: keeping Ulauncher's
    # window shadow makes it reserve transparent space around the panel, which
    # is what lets the theme's macOS-style drop shadow render instead of being
    # clipped to the window edge.
    systemd.user.services.ulauncher = {
      Unit = {
        Description = "Ulauncher application launcher";
        Documentation = "https://ulauncher.io";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Keep the Ulauncher theme in sync with the GNOME color scheme + accent color
    # and apply changes live. Also performs the initial theme install on start.
    systemd.user.services.ulauncher-theme = {
      Unit = {
        Description = "Sync the Ulauncher theme to the GNOME color scheme & accent";
        PartOf = [ "graphical-session.target" ];
        After = [ "ulauncher.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${themeWatch}/bin/ulauncher-theme-watch";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
