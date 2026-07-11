{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions.user-avatar-in-quick-settings;
in
{
  options.features.extensions.user-avatar-in-quick-settings.enable =
    lib.mkEnableOption "the User Avatar in Quick Settings GNOME Shell extension";

  # Shows the user's avatar in the Quick Settings panel.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.extensions.enable = true; # pull in the base plumbing (bools merge cleanly)
    gnomeShellExtensions = [ "quick-settings-avatar@d-go" ];
    # Upstream defaults (pop-up mode, no background) are already sensible -
    # no overrides needed.
  };
}
