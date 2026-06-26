_: {
  # TODO: fill in your work git identity.
  features.git = {
    enable = true;
    userName = "Dan Greco";
    lfs.enable = true;
  };

  features.fish.enable = true;
  features.direnv.enable = true;
  features.cli.enable = true;

  features.update = {
    enable = true;
    profile = "work";
  };
}
