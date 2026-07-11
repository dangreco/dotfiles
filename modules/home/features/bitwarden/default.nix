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

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = with pkgs; [
      bitwarden-cli
      bitwarden-desktop
    ];

    home.sessionVariables = {
      SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
    };

    # Declaratively mask the GCR SSH agent services
    xdg.configFile."systemd/user/gcr-ssh-agent.socket".source =
      config.lib.file.mkOutOfStoreSymlink "/dev/null";
    xdg.configFile."systemd/user/gcr-ssh-agent.service".source =
      config.lib.file.mkOutOfStoreSymlink "/dev/null";
  };
}
