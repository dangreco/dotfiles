#!/bin/sh
# Bootstrap dangreco's home-manager dotfiles on a fresh machine.
#
# Installs Nix (via the Determinate Systems installer) if it's missing, prompts
# for a profile, and applies the config straight from GitHub — nothing to clone.
# Works on ostree/atomic distros (Fedora Silverblue, Kinoite, Bluefin, …) where
# the Nix store is set up behind a systemd mount.
#
#   curl -fsSL https://raw.githubusercontent.com/dangreco/dotfiles/main/install.sh | sh
#
# Pick a profile non-interactively with an arg or env var:
#   ... | sh -s -- work
#   PROFILE=work ... | sh

set -eu

REPO="github:dangreco/dotfiles"
PROFILES="dan work"
DEFAULT_PROFILE="dan"
FLAKE_FEATURES="nix-command flakes"

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Detect the flake system string (matches lib/default.nix).
# ---------------------------------------------------------------------------
detect_system() {
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)  kernel="linux" ;;
    Darwin) kernel="darwin" ;;
    *)      err "unsupported OS: $os" ;;
  esac
  case "$arch" in
    x86_64|amd64)   cpu="x86_64" ;;
    aarch64|arm64)  cpu="aarch64" ;;
    *)              err "unsupported architecture: $arch" ;;
  esac
  printf '%s-%s\n' "$cpu" "$kernel"
}

SYSTEM="$(detect_system)"
info "Detected system: $SYSTEM"

# ---------------------------------------------------------------------------
# ostree / atomic detection (informational; Determinate handles both paths).
# ---------------------------------------------------------------------------
IS_OSTREE=0
if [ -f /run/ostree-booted ]; then
  IS_OSTREE=1
  info "ostree/atomic OS detected — Nix store will live behind a systemd mount."
fi

# ---------------------------------------------------------------------------
# Transient root (ostree/composefs).
#
# On composefs-backed atomic distros `/` is read-only. A *transient* root makes
# `/` a writable overlay that resets each boot. It's configured via
# prepare-root.conf and baked into the initramfs with `rpm-ostree initramfs-etc`
# (no dracut run). It only takes effect after a reboot, so we stage it and ask
# the user to reboot, then bail — the next run continues once it's active.
# ---------------------------------------------------------------------------
if [ "$IS_OSTREE" -eq 1 ] && ! findmnt / | grep -q "overlay"; then
  PREPARE_ROOT=/etc/ostree/prepare-root.conf
  if ! grep -qs 'transient[[:space:]]*=[[:space:]]*true' "$PREPARE_ROOT"; then
    info "Enabling transient root ..."
    sudo tee "$PREPARE_ROOT" >/dev/null <<'EOL'
[composefs]
enabled = yes
[root]
transient = true
EOL
    sudo rpm-ostree initramfs-etc --track="$PREPARE_ROOT"
  fi
  warn "Transient root is staged but not active — reboot, then re-run this script."
  exit 1
fi

# ---------------------------------------------------------------------------
# Make `nix` available on PATH in the current shell after an install.
# ---------------------------------------------------------------------------
load_nix() {
  for p in \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    "${HOME}/.nix-profile/etc/profile.d/nix.sh"; do
    # shellcheck disable=SC1090
    [ -e "$p" ] && . "$p"
  done
  return 0
}

# ---------------------------------------------------------------------------
# Install Nix if it's not already present.
# ---------------------------------------------------------------------------
if ! command -v nix >/dev/null 2>&1; then
  load_nix
fi

if ! command -v nix >/dev/null 2>&1; then
  info "Nix not found — installing via the Determinate Systems installer."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  load_nix

  if ! command -v nix >/dev/null 2>&1; then
    if [ "$IS_OSTREE" -eq 1 ]; then
      warn "Nix is installed but not active yet."
      warn "On ostree, the store mount may need a reboot to activate. Either:"
      warn "  sudo systemctl start nix.mount nix-daemon"
      warn "or reboot, then re-run this script."
    else
      warn "Nix is installed but not on PATH. Open a new shell and re-run this script."
    fi
    exit 1
  fi
else
  info "Nix already installed."
fi

# ---------------------------------------------------------------------------
# Pick the profile (arg > env > prompt > default).
# ---------------------------------------------------------------------------
valid_profile() {
  for p in $PROFILES; do
    [ "$p" = "$1" ] && return 0
  done
  return 1
}

PROFILE="${1:-${PROFILE:-}}"

if [ -n "$PROFILE" ]; then
  valid_profile "$PROFILE" || err "unknown profile '$PROFILE' (choose from: $PROFILES)"
else
  while :; do
    printf 'Profiles: %s\n' "$PROFILES" > /dev/tty
    printf 'Which profile? [%s] ' "$DEFAULT_PROFILE" > /dev/tty
    read -r PROFILE < /dev/tty || PROFILE=""
    [ -z "$PROFILE" ] && PROFILE="$DEFAULT_PROFILE"
    if valid_profile "$PROFILE"; then
      break
    fi
    warn "unknown profile '$PROFILE' (choose from: $PROFILES)"
  done
fi

# ---------------------------------------------------------------------------
# Resolve the flake output for this host: <profile>@<login user>@<system>.
# The login user is baked into home.username, so it must be registered under
# the profile's `usernames` in flake.nix.
# ---------------------------------------------------------------------------
USER_NAME="$(id -un)"
TARGET="${PROFILE}@${USER_NAME}@${SYSTEM}"

if ! nix eval --refresh --extra-experimental-features "$FLAKE_FEATURES" \
  "${REPO}#homeConfigurations" --apply builtins.attrNames 2>/dev/null \
  | grep -q "\"${TARGET}\""; then
  err "no config '${TARGET}' — add '${USER_NAME}' to the '${PROFILE}' profile's \`usernames\` in flake.nix"
fi

# ---------------------------------------------------------------------------
# Apply the configuration.
# ---------------------------------------------------------------------------
info "Applying ${TARGET} from ${REPO} ..."
nix run --refresh --extra-experimental-features "$FLAKE_FEATURES" \
  github:nix-community/home-manager -- switch \
  --flake "${REPO}#${TARGET}"

info "Done. ${TARGET} is active."
if [ "$IS_OSTREE" -eq 1 ]; then
  info "The Nix store is mounted via systemd and persists across rpm-ostree updates."
fi
