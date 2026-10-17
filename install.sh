#!/bin/sh
# install.sh - one-shot installer for pwrate
#
# Installs gum (if missing), links pwrate into your PATH, installs the
# PipeWire config, and offers to restart PipeWire.
# Re-running it is safe: everything is idempotent.

set -e

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONF_SRC="$SCRIPT_DIR/.config/pipewire/pipewire.conf.d"

say() { printf '%s\n' "$*"; }
fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

usage() {
    say "Usage: ./install.sh [--system] [--no-restart]"
    say
    say "  --system      Install the PipeWire config to /etc/pipewire/pipewire.conf.d"
    say "                (system-wide, needs root) instead of ~/.config/pipewire"
    say "  --no-restart  Skip the PipeWire restart prompt"
    say "  -h, --help    Show this help"
}

SYSTEM=0
NO_RESTART=0
for arg in "$@"; do
    case $arg in
    --system) SYSTEM=1 ;;
    --no-restart) NO_RESTART=1 ;;
    -h | --help)
        usage
        exit 0
        ;;
    *) fail "Unknown option: $arg (see --help)" ;;
    esac
done

[ "$(uname -s)" = Linux ] || fail "pwrate only works on Linux"

have_root() {
    [ "$(id -u)" -eq 0 ] || command -v sudo >/dev/null 2>&1
}

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif have_root; then
    SUDO="sudo"
else
    SUDO=""
fi

# --- 1. Prerequisite: PipeWire ---------------------------------------------

command -v pw-metadata >/dev/null 2>&1 ||
    fail "PipeWire not found (pw-metadata missing). Install the 'pipewire' package first, then re-run ./install.sh"

# --- 2. Dependency: gum -----------------------------------------------------

install_gum() {
    say "gum not found - attempting to install it..."
    if command -v pacman >/dev/null 2>&1; then
        have_root || fail "need root or sudo to install gum via pacman"
        $SUDO pacman -S --needed gum
    elif command -v dnf >/dev/null 2>&1; then
        have_root || fail "need root or sudo to install gum via dnf"
        $SUDO dnf install gum
    elif command -v yum >/dev/null 2>&1; then
        have_root || fail "need root or sudo to set up the Charm repo"
        say "Adding the Charm yum repository..."
        printf '%s\n' '[charm]' 'name=Charm' 'baseurl=https://repo.charm.sh/yum/' 'enabled=1' 'gpgcheck=1' 'gpgkey=https://repo.charm.sh/yum/gpg.key' |
            $SUDO tee /etc/yum.repos.d/charm.repo >/dev/null
        $SUDO rpm --import https://repo.charm.sh/yum/gpg.key
        $SUDO yum install gum
    elif command -v apt-get >/dev/null 2>&1; then
        have_root || fail "need root or sudo to set up the Charm apt repository"
        command -v curl >/dev/null 2>&1 || fail "curl is required to add the Charm apt repository"
        command -v gpg >/dev/null 2>&1 || fail "gpg (package gnupg) is required to add the Charm apt repository"
        say "Adding the Charm apt repository..."
        $SUDO mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" |
            $SUDO tee /etc/apt/sources.list.d/charm.list >/dev/null
        $SUDO apt update && $SUDO apt install gum
    elif command -v zypper >/dev/null 2>&1; then
        have_root || fail "need root or sudo to set up the Charm repo"
        say "Adding the Charm repository..."
        printf '%s\n' '[charm]' 'name=Charm' 'baseurl=https://repo.charm.sh/yum/' 'enabled=1' 'gpgcheck=1' 'gpgkey=https://repo.charm.sh/yum/gpg.key' |
            $SUDO tee /etc/yum.repos.d/charm.repo >/dev/null
        $SUDO rpm --import https://repo.charm.sh/yum/gpg.key
        $SUDO zypper refresh
        $SUDO zypper install gum
    elif command -v brew >/dev/null 2>&1; then
        brew install gum
    elif command -v nix-env >/dev/null 2>&1; then
        nix-env -iA nixpkgs.gum
    elif command -v go >/dev/null 2>&1; then
        go install charm.land/gum/v2@latest
    else
        fail "Could not auto-install gum. Install it manually: https://github.com/charmbracelet/gum#installation"
    fi
}

if ! command -v gum >/dev/null 2>&1; then
    install_gum
    if ! command -v gum >/dev/null 2>&1; then
        # go install puts binaries in $HOME/go/bin, which is often not in PATH yet.
        if [ -x "$HOME/go/bin/gum" ]; then
            say "gum installed to $HOME/go/bin - add it to your PATH:"
            say "  export PATH=\"\$HOME/go/bin:\$PATH\""
            PATH="$HOME/go/bin:$PATH"
            export PATH
        else
            fail "gum installation was attempted but 'gum' is still not on your PATH. See https://github.com/charmbracelet/gum#installation"
        fi
    fi
    say "gum ready: $(command -v gum)"
else
    say "gum already installed: $(command -v gum)"
fi

# --- 3. Link pwrate into PATH -----------------------------------------------

chmod +x "$SCRIPT_DIR/pwrate"

case ":$PATH:" in
*":$HOME/.local/bin:"*) BINDIR="$HOME/.local/bin" ;;
*) BINDIR="/usr/local/bin" ;;
esac

if [ "$BINDIR" = "/usr/local/bin" ]; then
    have_root || fail "need root or sudo to write /usr/local/bin (or add ~/.local/bin to your PATH)"
    $SUDO mkdir -p "$BINDIR"
    $SUDO ln -sfn "$SCRIPT_DIR/pwrate" "$BINDIR/pwrate"
else
    mkdir -p "$BINDIR"
    ln -sfn "$SCRIPT_DIR/pwrate" "$BINDIR/pwrate"
fi
say "Linked $BINDIR/pwrate -> $SCRIPT_DIR/pwrate"

# --- 4. PipeWire config ------------------------------------------------------

if [ "$SYSTEM" -eq 1 ]; then
    have_root || fail "need root or sudo for --system"
    CONF_DEST="/etc/pipewire/pipewire.conf.d"
    CONF_SUDO="$SUDO"
else
    CONF_DEST="$HOME/.config/pipewire/pipewire.conf.d"
    CONF_SUDO=""
fi

$CONF_SUDO mkdir -p "$CONF_DEST"

for src in "$CONF_SRC"/*.conf; do
    [ -f "$src" ] || continue
    name=$(basename "$src")
    if [ -f "$CONF_DEST/$name" ]; then
        if cmp -s "$src" "$CONF_DEST/$name"; then
            say "Config $name already installed, unchanged"
            continue
        fi
        say "Existing $name differs - backing up to $name.bak"
        $CONF_SUDO cp "$CONF_DEST/$name" "$CONF_DEST/$name.bak"
    fi
    $CONF_SUDO cp "$src" "$CONF_DEST/$name"
    say "Installed $name -> $CONF_DEST/$name"
done

# --- 5. Restart PipeWire -----------------------------------------------------

if [ "$NO_RESTART" -eq 0 ] && command -v systemctl >/dev/null 2>&1; then
    printf 'Restart PipeWire now to apply the config? [Y/n] '
    read -r ans || ans=""
    case $ans in
    n | N | no | NO)
        say "Skipped restart - apply later with: systemctl --user restart pipewire"
        ;;
    *)
        if systemctl --user restart pipewire; then
            say "PipeWire restarted"
        else
            say "Warning: could not restart pipewire service - try: systemctl --user restart pipewire"
        fi
        ;;
    esac
fi

# --- Summary ------------------------------------------------------------------

say ""
say "pwrate installed!"
say "  Run it with: pwrate"
say "  Config file: $CONF_DEST"
say "  Menu engine: $(command -v gum)"
