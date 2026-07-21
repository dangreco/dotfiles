{
  description = "dangreco's home-manager dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ulauncher-theme-gnome = {
      url = "github:aceydot/ulauncher-theme-gnome";
      flake = false;
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak?ref=latest";
    home-manager-brew = {
      url = "github:koalalorenzo/home-manager-brew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      lib' = import ./lib inputs;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      inherit (lib') systems;

      imports = [ inputs.git-hooks.flakeModule ];

      perSystem =
        { config, pkgs, ... }:
        {
          formatter = pkgs.nixfmt;

          # `nix flake check` runs these; the git pre-commit hook (installed on
          # devShell entry below) runs them against staged files on commit.
          pre-commit.settings.hooks = {
            nixfmt.enable = true; # format (same nixfmt as `formatter`)
            deadnix.enable = true; # lint: dead/unused code
            statix = {
              enable = true; # lint: nix anti-patterns
              settings.config = ".statix.toml"; # statix doesn't auto-discover it
            };
          };

          # `nix develop` (or direnv `use flake`) installs the git hook.
          devShells.default = pkgs.mkShell {
            inputsFrom = [ config.pre-commit.devShell ];
            packages =
              with pkgs;
              [
                nil
                nixd
                nixfmt
              ]
              ++ config.pre-commit.settings.enabledPackages;
          };
        };

      # Each profile is built for every username x system, keyed
      # `<profile>@<username>@<system>` (dan@dan@x86_64-linux,
      # work@work@aarch64-darwin, work@dangreco@aarch64-darwin, and so on).
      # `usernames` defaults to `[ "<profile>" ]`.
      flake.homeConfigurations = lib'.mkHomes {
        dan = {
          module = ./profiles/dan.nix;
        };
        work = {
          module = ./profiles/work.nix;
          usernames = [
            "work"
            "dangreco"
          ];
        };
      };
    };
}
