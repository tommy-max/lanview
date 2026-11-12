#!/usr/bin/env bash
set -e

echo "=== LanView Installer ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Check / install PyQt6
if ! python3 -c "import PyQt6" >/dev/null 2>&1; then
    echo "-> Installing PyQt6..."
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm python-pyqt6
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y python3-pyqt6
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3-pyqt6
    else
        pip3 install --user PyQt6
    fi
fi

# 2. Install executable
mkdir -p "$HOME/.local/bin"
cp -f "$SCRIPT_DIR/lanview" "$HOME/.local/bin/lanview"
chmod +x "$HOME/.local/bin/lanview"

# 3. Create station config directory & copy example if empty
mkdir -p "$HOME/.config/lanview/stations"
chmod 700 "$HOME/.config/lanview" "$HOME/.config/lanview/stations"
if [ -z "$(ls -A "$HOME/.config/lanview/stations/"*.json 2>/dev/null)" ]; then
    cp "$SCRIPT_DIR/stations/ws1.example.json" "$HOME/.config/lanview/stations/ws1.json"
    chmod 600 "$HOME/.config/lanview/stations/ws1.json"
    echo "-> Created example station config at ~/.config/lanview/stations/ws1.json"
fi

# 4. Install icons
mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps" "$HOME/.local/share/icons/hicolor/256x256/apps"
cp -f "$SCRIPT_DIR/assets/lanview.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/lanview.svg"
cp -f "$SCRIPT_DIR/assets/lanview.png" "$HOME/.local/share/icons/hicolor/256x256/apps/lanview.png"

# 5. Create Desktop entry
mkdir -p "$HOME/.local/share/applications"
cat << DESKTOP > "$HOME/.local/share/applications/lanview.desktop"
[Desktop Entry]
Type=Application
Name=LanView Remote Desktop
Comment=Unattended Linux/Wayland Remote Desktop over SSH (DRM/KMS + uinput)
Exec=$HOME/.local/bin/lanview
Icon=$HOME/.local/share/icons/hicolor/scalable/apps/lanview.svg
Terminal=false
Categories=Network;RemoteAccess;System;
Keywords=remote;desktop;wayland;ssh;kms;uinput;screen;sharing;
StartupNotify=true
StartupWMClass=lanview
DESKTOP

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "✅ LanView installed successfully!"
echo "   Run from your application launcher ('LanView Remote Desktop') or via:"
echo "   ~/.local/bin/lanview"
