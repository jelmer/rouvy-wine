#!/bin/sh
set -e

URL="https://cdn.rouvy.com/update/Rouvy_Installer.exe"
DEST_DIR="${1:-.}"

mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

echo "Downloading ROUVY Windows installer..."
curl -fL --progress-bar -OJ "$URL"
echo "Done."
