#!/bin/sh
# Entry point for the rouvy container. Seeds /data from the template
# prefix baked into the image on first run, then launches ROUVY under the
# patched Wine overlay.
set -e

DATA_DIR="${DATA_DIR:-/data}"
PREFIX="$DATA_DIR/prefix"
TEMPLATE="/opt/rouvy-prefix"
WINE=/opt/wine-overlay/bin/wine
WINESERVER=/opt/wine-overlay/bin/wineserver

if [ ! -d "$DATA_DIR" ]; then
    echo "no $DATA_DIR mounted; pass '-v rouvy-data:/data' to podman run" >&2
    exit 1
fi

if [ ! -f "$PREFIX/.installed" ]; then
    echo "seeding Wine prefix in $PREFIX from $TEMPLATE ..."
    mkdir -p "$PREFIX"
    cp -a "$TEMPLATE/." "$PREFIX/"
    touch "$PREFIX/.installed"
fi

export WINEPREFIX="$PREFIX"
export WINEDEBUG="${WINEDEBUG:--all}"

# Drivers like winebth.sys are loaded once per wineserver, so make sure no
# stale server from a prior run is still around.
"$WINESERVER" -k 2>/dev/null || true

rouvy_exe="$WINEPREFIX/drive_c/Program Files/VirtualTraining/Rouvy/Rouvy.exe"

if [ -n "$ROUVY_DESKTOP" ]; then
    # Register the desktop under its own name so Wine uses this size for the
    # virtual-desktop window and Rouvy's internal layout is sized for it.
    "$WINE" reg add "HKCU\\Software\\Wine\\Explorer\\Desktops" \
        /v "${ROUVY_DESKTOP_NAME:-rouvy}" /t REG_SZ /d "$ROUVY_DESKTOP" /f \
        >/dev/null 2>&1
    "$WINESERVER" -w
    if [ $# -eq 0 ]; then
        set -- "$rouvy_exe"
    fi
    exec "$WINE" explorer "/desktop=${ROUVY_DESKTOP_NAME:-rouvy},$ROUVY_DESKTOP" "$@"
fi

if [ $# -eq 0 ]; then
    set -- "$rouvy_exe"
fi

exec "$WINE" "$@"
