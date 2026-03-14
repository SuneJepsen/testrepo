#!/usr/bin/env bash
set -euo pipefail

# --------- 0. Preflight ----------
# Kræv curl, tar ikke nødvendig fordi vi henter en ren binær.
if ! command -v curl >/dev/null 2>&1; then
  echo "Fejl: 'curl' er ikke installeret. Installer curl og prøv igen." >&2
  exit 1
fi

# --------- 1. Detect OS + ARCH ----------
OS="$(uname -s)"
ARCH="$(uname -m)"

# Dine RAW-URL'er (eller Release-URL'er)
BINARY_URL_DARWIN_ARM64="https://raw.githubusercontent.com/SuneJepsen/testrepo/main/skilltir-install-darwin-arm64"
BINARY_URL_DARWIN_AMD64="https://raw.githubusercontent.com/SuneJepsen/testrepo/main/skilltir-install-darwin-amd64"
BINARY_URL_LINUX_AMD64="https://raw.githubusercontent.com/SuneJepsen/testrepo/main/skilltir-install-linux-amd64"

case "$OS" in
  Darwin)
    case "$ARCH" in
      arm64)  BINARY_URL="$BINARY_URL_DARWIN_ARM64" ;;
      x86_64) BINARY_URL="$BINARY_URL_DARWIN_AMD64" ;;
      *) echo "Unsupported macOS architecture: $ARCH" >&2; exit 1 ;;
    esac
    ;;
  Linux)
    case "$ARCH" in
      x86_64) BINARY_URL="$BINARY_URL_LINUX_AMD64" ;;
      *) echo "Unsupported Linux architecture: $ARCH" >&2; exit 1 ;;
    esac
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

# --------- 2. Installationsstier (per-user; MSI-ækvivalent) ----------
INSTALL_ROOT="$HOME/.local/Programs/Skilltir"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_ROOT" "$BIN_DIR"

# --------- 3. Download + install ----------
TARGET_BIN="$INSTALL_ROOT/skilltir"
echo "Henter Skilltir CLI til: $TARGET_BIN"
curl -fL --retry 3 --connect-timeout 10 "$BINARY_URL" -o "$TARGET_BIN"

# Gør eksekverbar
chmod +x "$TARGET_BIN"

# Symlink til PATH-mapppen
ln -sf "$TARGET_BIN" "$BIN_DIR/skilltir"

# --------- 4. PATH-opsætning (idempotent) ----------
detect_shell_rc() {
  # Prioritér brugerens aktuelle shell
  if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL##*/}" = "zsh" ]; then
    echo "$HOME/.zshrc"
  elif [ -n "${BASH_VERSION:-}" ] || [ "${SHELL##*/}" = "bash" ]; then
    # Ubuntu bruger .bashrc; macOS bash-brugere har ofte .bash_profile
    if [ -f "$HOME/.bashrc" ]; then echo "$HOME/.bashrc"; else echo "$HOME/.bash_profile"; fi
  else
    echo "$HOME/.profile"
  fi
}

SHELL_RC="$(detect_shell_rc)"

# Tilføj kun hvis ikke allerede til stede
if [ -f "$SHELL_RC" ]; then
  if ! grep -qsE '(^|\s)export PATH=.*/\.local/bin' "$SHELL_RC"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    ADDED_PATH_MSG="Added $BIN_DIR to PATH in $SHELL_RC"
  fi
else
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
  ADDED_PATH_MSG="Created $SHELL_RC and added $BIN_DIR to PATH"
fi

echo
echo "✅ Skilltir CLI er installeret."
echo "   Binær: $TARGET_BIN"
echo "   Symlink: $BIN_DIR/skilltir"
[ -n "${ADDED_PATH_MSG:-}" ] && echo "   $ADDED_PATH_MSG"
echo
echo "Kør:  skilltir --version"
echo "Hvis 'skilltir' ikke findes endnu, kør:  source \"$SHELL_RC\"  eller åbne et nyt terminalvindue."