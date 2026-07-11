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
    profile = "work";
  };
}
