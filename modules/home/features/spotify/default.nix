{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.spotify;
in
{
  options.features.spotify.enable = lib.mkEnableOption "Spotify (Flatpak)";

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    features.flatpak.enable = true; # pull in the base plumbing (bools merge cleanly)
    services.flatpak.packages = [ "com.spotify.Client" ];

    # Spotify (CEF) defaults to native Wayland but doesn't draw client-side window
    # decorations there, so on GNOME/Wayland it renders a broken Chromium-style
    # title bar instead of the native one. Until upstream bumps CEF to a version
    # that decorates Wayland windows, pin Spotify to X11/XWayland so it gets a
    # proper title bar. Mirrors the documented workaround:
    #   flatpak override --user --unset-env=XDG_SESSION_TYPE --socket=x11 --nosocket=wayland com.spotify.Client
    # https://github.com/flathub/com.spotify.Client/issues/317
    services.flatpak.overrides."com.spotify.Client".Context = {
      sockets = [
        "x11"
        "!wayland"
      ];
      unset-environment = [ "XDG_SESSION_TYPE" ];
    };
  };
}
