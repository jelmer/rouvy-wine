#!/bin/sh
# Run ROUVY with the patched Wine from wine-overlay (see build.sh).
set -e

dir="$(dirname "$(readlink -f "$0")")"
wine="$dir/wine-overlay/bin/wine"

[ -x "$wine" ] || "$dir/build.sh"

# Drivers such as winebth.sys are loaded once per wineserver, so a server
# started by the unpatched Wine keeps using the unpatched Bluetooth driver.
if pgrep -u "$(id -u)" -x wineserver >/dev/null; then
    echo "warning: a wineserver is already running; if Bluetooth does not work," >&2
    echo "close other Wine programs, run '$dir/wine-overlay/bin/wineserver -k' and try again" >&2
fi

exec "$wine" "${WINEPREFIX:-$HOME/.wine}/drive_c/Program Files/VirtualTraining/Rouvy/Rouvy.exe" "$@"
