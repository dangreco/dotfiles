{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.extensions;
  uuids = config.gnomeShellExtensions;

  # Static at eval time: each per-extension feature contributes its UUID to
  # `gnomeShellExtensions`, so the list of extensions to sync is known up
  # front and baked directly into the script (no runtime discovery needed).
  sync = pkgs.writeShellApplication {
    name = "gnome-extensions-sync";
    # `glib` provides glib-compile-schemas, which the filesystem backend runs
    # after installing/updating so the new extensions' settings are readable.
    runtimeInputs = [
      pkgs.gnome-extensions-cli
      pkgs.glib
    ];
    text = ''
      # --filesystem: talk to ~/.local/share/gnome-shell/extensions directly
      # instead of the D-Bus shell API, so this works headless/at login with
      # no confirmation prompt and no running shell session required.
      # --install: fetch any UUID below that isn't installed yet.
      # --yes: never prompt (this runs unattended from a systemd service).
      # gext resolves, for each UUID, the newest release compatible with the
      # *installed* GNOME Shell version - not a version pinned by Nix - so
      # this naturally tracks whatever shell the host is running.
      gext --filesystem update --install --yes ${lib.concatMapStringsSep " " lib.escapeShellArg uuids}
    '';
  };
in
{
  imports = [
    ./appindicator.nix
    ./caffeine.nix
    ./clipboard-indicator.nix
    ./freon.nix
    ./just-perfection.nix
    ./tophat.nix
    ./user-avatar-in-quick-settings.nix
  ];
  options.features.extensions.enable = lib.mkEnableOption "GNOME Shell extension management (extensions.gnome.org, auto-updated)";

  options.gnomeShellExtensions = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    internal = true;
    description = ''
      UUIDs of GNOME Shell extensions to install from extensions.gnome.org and
      enable. Per-extension feature modules append to this list; it is not
      meant to be set directly from a profile.
    '';
  };

  # GNOME Shell extensions are Linux-only; on darwin this stays off and the
  # option decls are inert, same as the `flatpak` base feature.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ pkgs.gnome-extensions-cli ];

    dconf.settings."org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = uuids;
    };

    # Install/update at login, then re-check daily so extensions stay current
    # without needing a manual `gext update` - the Extension Manager model,
    # but driven by a timer instead of a GUI.
    systemd.user.services.gnome-extensions-sync = {
      Unit = {
        Description = "Install/update GNOME Shell extensions from extensions.gnome.org";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${sync}/bin/gnome-extensions-sync";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    systemd.user.timers.gnome-extensions-sync = {
      Unit.Description = "Daily GNOME Shell extension update check";
      Timer = {
        OnCalendar = "daily";
        Persistent = true; # catch up if the machine was off/asleep at the scheduled time
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
