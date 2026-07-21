# dotfiles

Standalone [home-manager](https://github.com/nix-community/home-manager) configuration
for managing user-level dotfiles on any OS Nix runs on (non-NixOS Linux, macOS, WSL).
No NixOS or nix-darwin required. Config is split into per-identity profiles (`dan`,
`work`) built from feature modules you toggle on and off.

## Install from scratch

On a fresh machine, one line pulls everything from GitHub — no clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/dangreco/dotfiles/main/install.sh | sh
```

It installs Nix via the [Determinate Systems installer](https://install.determinate.systems/nix)
if it's missing (this also works on ostree/atomic distros — Fedora Silverblue,
Kinoite, Bluefin — where the Nix store is set up behind a systemd mount),
detects your system, prompts for a profile, then applies it.

Skip the prompt with an arg or env var:

```bash
curl -fsSL https://raw.githubusercontent.com/dangreco/dotfiles/main/install.sh | sh -s -- work
# or
PROFILE=work curl -fsSL https://raw.githubusercontent.com/dangreco/dotfiles/main/install.sh | sh
```

On a brand-new ostree install the store mount may need a reboot to activate; if
the script says so, reboot (or `sudo systemctl start nix.mount nix-daemon`) and
re-run it.

## Activate

With home-manager already installed:

```bash
home-manager switch --flake .#<profile>@<username>@<system>
# e.g.
home-manager switch --flake .#dan@dan@x86_64-linux
home-manager switch --flake .#work@dangreco@aarch64-darwin
```

`<username>` is your login user (`id -un`); it must be listed under the
profile's `usernames` in `flake.nix`.

First time, without home-manager installed:

```bash
nix run github:nix-community/home-manager -- switch --flake .#dan@dan@x86_64-linux
```

## Updating

A background service checks `github:dangreco/dotfiles` for a newer commit every
6 hours (and shortly after login). When one is available, interactive `fish`
sessions prompt on launch:

```
:: dotfiles update available (a1b2c3d → v1.2.0).
Update now? [y/N]
```

Each side is a **release tag** if that commit is tagged (e.g. `v1.2.0`), else a
short commit SHA. Answering `y` applies the update; `N` (or Enter) snoozes the
prompt for 6 hours so new tabs don't re-nag. Update on demand at any time:

```bash
dotfiles-update
```

which runs `home-manager switch --refresh --flake github:dangreco/dotfiles#<profile>@<username>@<system>`.
Local development builds (a dirty/checkout tree, `.#dan@...`) have no baked
revision, so the check is a no-op and never nags.

## Profiles

Every profile is generated for every username x system, keyed
`<profile>@<username>@<system>`. A profile can list several `usernames` so the
same identity runs on hosts whose login user differs from the profile name.

| Profile | Identity                    | Usernames        |
| ------- | --------------------------- | ---------------- |
| `dan`   | Dan Greco                   | `dan`            |
| `work`  | work identity (placeholder) | `work`, `dangreco` |

Supported systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`, `x86_64-darwin`.

## Layout

```
flake.nix              # inputs + profile registry (flake-parts)
lib/                   # systems list + mkHome / mkHomes (profile x system matrix)
modules/home/          # feature modules you toggle on and off
  features/{avatar,cli,dconf,dejadup,direnv,extensions,fish,flatpak,gimp,git,slack,spotify,ulauncher,update,zed}/
  features/extensions/{appindicator,caffeine,clipboard-indicator,freon,just-perfection,tophat,user-avatar-in-quick-settings}.nix
profiles/              # identities: flip feature toggles, set values
```

## Add a profile

1. Create `profiles/<name>.nix` flipping the feature toggles you want.
2. Register it in `flake.nix` under `flake.homeConfigurations`:

   ```nix
   <name> = { module = ./profiles/<name>.nix; };
   ```

   `usernames` defaults to `[ "<name>" ]`; list every login user the profile
   may run under with
   `<name> = { module = ./profiles/<name>.nix; usernames = [ "..." "..." ]; };`.

## Add a feature

1. Create `modules/home/features/<name>/default.nix` defining an option
   `features.<name>.enable` (plus any params) and wrapping config in
   `lib.mkIf cfg.enable`.
2. Add it to the `imports` list in `modules/home/features/default.nix`.
3. Enable it from any profile: `features.<name>.enable = true;`.

## GNOME Shell extensions

GNOME extensions are pulled from [extensions.gnome.org](https://extensions.gnome.org)
at their latest shell-compatible version (not pinned to nixpkgs) and kept current by a
daily timer via [`gext`](https://github.com/essembeh/gnome-extensions-cli). Toggle each
one under `features.extensions`:

```nix
features.extensions.caffeine.enable = true;
features.extensions.just-perfection.enable = true;
```

Each extension ships opinionated `dconf` defaults; enabling one auto-pulls the shared
machinery (`features.extensions.enable`). First activation needs a shell reload
(log out/in on Wayland) for the new extensions to appear.

## OS-gating

Feature config that only applies on one platform is gated with `pkgs.stdenv`:

```nix
{ config, lib, pkgs, ... }:
lib.mkIf cfg.enable {
  home.packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.someLinuxOnlyTool ];
  # or: lib.mkIf pkgs.stdenv.isDarwin { ... }
}
```
