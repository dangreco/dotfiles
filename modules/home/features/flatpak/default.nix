{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.features.flatpak;
in
{
  # Always import the module so `services.flatpak.*` options exist whenever an app
  # feature (dejadup/gimp) appends to services.flatpak.packages. Inert until enabled.
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  options.features.flatpak.enable = lib.mkEnableOption "declarative Flatpak app management (nix-flatpak, Flathub)";

  # Flatpak is Linux-only; on darwin this stays off and the import is just option decls.
  # nix-flatpak adds the Flathub remote by default, so no explicit `remotes` needed.
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    services.flatpak.enable = true;

    # Update managed apps when the config is activated (home-manager switch), then
    # keep them current on a weekly systemd timer. Commit-pinned apps are skipped.
    services.flatpak.update.onActivation = true;
    services.flatpak.update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}
