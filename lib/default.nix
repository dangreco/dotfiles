inputs:
let
  inherit (inputs) nixpkgs home-manager;
  inherit (nixpkgs) lib;

  # The systems every profile is built for; also used as flake-parts' `systems`.
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];

  # Build one standalone home-manager configuration for a profile/system pair.
  mkHome =
    {
      username,
      system,
      module,
    }:
    let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-39.8.10"
          ];
        };
      };
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ../modules/home
        module
        {
          home.username = lib.mkDefault username;
          home.homeDirectory = lib.mkDefault (
            if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}"
          );
        }
      ];
    };

  # Expand a registry of profiles into a `<profile>@<username>@<system>` attrset
  # of home-manager configurations. A profile may run under several login
  # usernames (`usernames`, defaulting to `[ name ]`) so the same profile can be
  # applied on hosts whose login user differs from the profile name.
  mkHomes =
    profiles:
    lib.listToAttrs (
      lib.concatMap (
        name:
        let
          profile = profiles.${name};
        in
        lib.concatMap (
          username:
          map (
            system:
            lib.nameValuePair "${name}@${username}@${system}" (mkHome {
              inherit username system;
              inherit (profile) module;
            })
          ) systems
        ) (profile.usernames or [ name ])
      ) (lib.attrNames profiles)
    );
in
{
  inherit systems mkHome mkHomes;
}
