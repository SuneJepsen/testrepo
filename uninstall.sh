#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT="$HOME/.local/Programs/Skilltir"
BIN_DIR="$HOME/.local/bin"
TARGET_BIN="$BIN_DIR/skilltir"

echo "Afinstallerer Skilltir CLI ..."

rm -f "$TARGET_BIN"
rm -rf "$INSTALL_ROOT"

# Ryd eventuel PATH-linje (forsigtig; kun hvis den ligner præcis vores)
for RC in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  [ -f "$RC" ] || continue
  if grep -qsF 'export PATH="$HOME/.local/bin:$PATH"' "$RC"; then
    # macOS sed -i kræver tom '' arg; Linux kan nøjes med -i
    if sed -i '' 's|export PATH="$HOME/.local/bin:$PATH"||' "$RC" 2>/dev/null; then :; else
      sed -i 's|export PATH="$HOME/.local/bin:$PATH"||' "$RC" || true
    fi
  fi
done

echo "✅ Skilltir CLI er fjernet."