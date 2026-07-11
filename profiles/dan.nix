_: {
  features.git = {
    enable = true;
    userName = "Dan Greco";
    userEmail = "git@dangre.co";
    lfs.enable = true;
  };

  features.avatar = {
    enable = true;
    username = "dangreco";
  };

  features.fish.enable = true;
  features.direnv.enable = true;
  features.cli.enable = true;
  features.ulauncher.enable = true;
  features.gimp.enable = true;
  features.slack.enable = true;
  features.spotify.enable = true;
  # GNOME Shell extensions (extensions.gnome.org, auto-updated)
  features.extensions.appindicator.enable = true;
  features.extensions.caffeine.enable = true;
  features.extensions.clipboard-indicator.enable = true;
  features.extensions.freon.enable = true;
  features.extensions.just-perfection.enable = true;
  features.extensions.tophat.enable = true;
  features.extensions.user-avatar-in-quick-settings.enable = true;

  features.dconf = {
    enable = true;

    touchpadTapToClick = false;
    naturalScrolling = true;
    showBatteryPercentage = true;

    favoriteApps = [
      "org.gnome.Nautilus.desktop"
      "org.mozilla.firefox.desktop"
    ];
  };

  features.update = {
    enable = true;
    profile = "dan";
  };
}
