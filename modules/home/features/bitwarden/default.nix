{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.bitwarden;
in
{
  options.features.bitwarden.enable = lib.mkEnableOption "Bitwarden";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # Bitwarden's SSH agent exposes the same socket path on both platforms.
        home.sessionVariables = {
          SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
        };
      }
      (lib.mkIf pkgs.stdenv.isLinux {
        home.packages = with pkgs; [
          bitwarden-cli
          bitwarden-desktop
        ];

        # Declaratively mask the GCR SSH agent services (systemd, Linux-only)
        xdg.configFile."systemd/user/gcr-ssh-agent.socket".source =
          config.lib.file.mkOutOfStoreSymlink "/dev/null";
        xdg.configFile."systemd/user/gcr-ssh-agent.service".source =
          config.lib.file.mkOutOfStoreSymlink "/dev/null";
      })
      (lib.mkIf pkgs.stdenv.isDarwin {
        features.homebrew.enable = true;
        homebrew.casks = [ "bitwarden" ];
      })
    ]
  );
}
