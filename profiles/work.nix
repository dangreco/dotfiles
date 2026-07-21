_: {
  features.git = {
    enable = true;
    userName = "Dan Greco";
    lfs.enable = true;
  };

  features.fish.enable = true;
  features.direnv.enable = true;
  features.cli.enable = true;
  features.ulauncher.enable = true;
  features.gimp.enable = true;
  features.dejadup.enable = true;
  features.slack.enable = true;
  features.spotify.enable = true;
  features.zed.enable = true;
  features.bitwarden.enable = true;
  features.chromium.enable = true;

  # GNOME Shell extensions (extensions.gnome.org, auto-updated)
  features.extensions.caffeine.enable = true;
  features.extensions.freon.enable = true;
  features.extensions.just-perfection.enable = true;
  features.extensions.tophat.enable = true;
  features.extensions.user-avatar-in-quick-settings.enable = true;
  features.extensions.medialine.enable = true;

  features.pipewire = {
    enable = true;
    disableAirplayDiscovery = true;
  };

  features.dconf = {
    enable = true;

    touchpadTapToClick = false;
    naturalScrolling = true;
    showBatteryPercentage = true;

    favoriteApps = [
      "org.gnome.Nautilus.desktop"
      "org.mozilla.firefox.desktop"
      "com.slack.Slack.desktop"
    ];
  };

  features.update = {
    enable = true;
    profile = "work";
  };
}
