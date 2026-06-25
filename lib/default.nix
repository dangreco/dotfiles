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
        config.allowUnfree = true;
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

  # Expand a registry of profiles into a `<profile>@<system>` attrset of
  # home-manager configurations. `username` defaults to the profile name.
  mkHomes =
    profiles:
    lib.listToAttrs (
      lib.concatMap (
        name:
        let
          profile = profiles.${name};
        in
        map (
          system:
          lib.nameValuePair "${name}@${system}" (mkHome {
            username = profile.username or name;
            inherit system;
            inherit (profile) module;
          })
        ) systems
      ) (lib.attrNames profiles)
    );
in
{
  inherit systems mkHome mkHomes;
}
