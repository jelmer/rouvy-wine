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

ss_timeout=""
dpms_enabled=""
if command -v xset >/dev/null 2>&1; then
    ss_timeout="$(xset q 2>/dev/null | awk '/timeout:/ { print $2; exit }')"
    dpms_enabled="$(xset q 2>/dev/null | awk '/DPMS is/ { print $3; exit }')"
    xset s off -dpms >/dev/null 2>&1 || true
fi

restore_screen() {
    if command -v xset >/dev/null 2>&1; then
        [ "$dpms_enabled" = "Enabled" ] && xset +dpms >/dev/null 2>&1 || true
        case "$ss_timeout" in
            ''|*[!0-9]*) ;;
            0) ;;
            *) xset s "$ss_timeout" >/dev/null 2>&1 || true ;;
        esac
    fi
}

cleanup() {
    trap - EXIT INT TERM
    restore_screen
}
trap cleanup EXIT INT TERM

"$wine" "${WINEPREFIX:-$HOME/.wine}/drive_c/Program Files/VirtualTraining/Rouvy/Rouvy.exe" "$@"

