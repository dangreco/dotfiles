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

  features.dconf = {
    enable = true;

    touchpadTapToClick = true;
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
