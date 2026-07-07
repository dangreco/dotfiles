{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.dconf;
in
{
  options.features.dconf = {
    enable = lib.mkEnableOption "GNOME desktop tweaks via dconf";

    touchpadTapToClick = lib.mkEnableOption "tap-to-click on touchpads";

    naturalScrolling = lib.mkEnableOption "natural scrolling (touchpad + mouse)";

    showBatteryPercentage = lib.mkEnableOption "the battery percentage in the top bar";

    favoriteApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of favorite apps to show in the dock";
    };
  };

  # dconf / GNOME is Linux-only; the same profile built for darwin skips this
  # entirely. Each schema map uses `optionalAttrs` so unset toggles emit no
  # `dconf write` and leave existing settings untouched.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    dconf.settings = {
      "org/gnome/desktop/peripherals/touchpad" =
        lib.optionalAttrs cfg.touchpadTapToClick { tap-to-click = true; }
        // lib.optionalAttrs cfg.naturalScrolling { natural-scroll = true; };

      "org/gnome/desktop/peripherals/mouse" = lib.optionalAttrs cfg.naturalScrolling {
        natural-scroll = true;
      };

      "org/gnome/desktop/interface" = lib.optionalAttrs cfg.showBatteryPercentage {
        show-battery-percentage = true;
      };

      "org/gnome/mutter" = {
        center-new-windows = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":minimize,maximize,close";
      };

      "org/gnome/shell" = {
        favorite-apps = cfg.favoriteApps;
      };

      "org/gnome/desktop/wm/keybindings" = {
        move-to-center = [ "<Super>c" ];
      };

      # GNOME only activates a custom shortcut once its path is registered in
      # this list; writing custom0's fields alone is inert without it.
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Open Terminal";
        command = "ptyxis --new-window";
        binding = "<Super>Return";
      };

      # ptyxis
      "org/gnome/Ptyxis" = {
        restore-session = false;
        restore-window-size = false;
        audible-bell = false;
        visual-bell = false;
        cursor-shape = "ibeam";
      };
    };
  };
}
