_: {
  features.git = {
    enable = true;
    userName = "Dan Greco";
    userEmail = "git@dangre.co";
    lfs.enable = true;
  };

  features.fish.enable = true;
  features.direnv.enable = true;
  features.cli.enable = true;

  features.update = {
    enable = true;
    profile = "dan";
  };
}
