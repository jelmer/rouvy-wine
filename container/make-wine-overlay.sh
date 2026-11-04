#!/bin/sh
# Create a shadow copy of the system Wine install with patched builtin DLLs.
#
# Wine looks up builtin DLLs relative to the real path of its ntdll.so before
# it consults WINEDLLPATH, so builtins can't be overridden from the
# environment. Copy the loader and ntdll.so, and symlink everything else.
set -e

WINE_SRC="${WINE_SRC:-/opt/wine-devel}"
dir="$(dirname "$(readlink -f "$0")")"
WINE_BUILD="${WINE_BUILD:-$dir/wine/build}"
DEST="${1:-$dir/wine-overlay}"
PATCHED_MODULES="${PATCHED_MODULES:-dnsapi.dll msvcp140.dll winebth.sys windows.devices.bluetooth.dll}"
PATCHED_UNIXLIBS="${PATCHED_UNIXLIBS:-winebth.sys/winebth.so}"

unixdir=lib/wine/x86_64-unix
pedir=lib/wine/x86_64-windows

rm -rf "$DEST"
mkdir -p "$DEST/bin" "$DEST/$unixdir" "$DEST/$pedir"

ln -s "$WINE_SRC/share" "$DEST/share"
for d in "$WINE_SRC"/lib/wine/*; do
    case "$(basename "$d")" in
        x86_64-unix|x86_64-windows) ;;
        *) ln -s "$d" "$DEST/lib/wine/" ;;
    esac
done

for f in "$WINE_SRC"/bin/*; do
    name="$(basename "$f")"
    if [ -L "$f" ]; then
        cp -P "$f" "$DEST/bin/"
    elif [ "$name" = wine ] || [ "$name" = wineserver ]; then
        # Copy rather than symlink: wine and wineserver share a protocol
        # version, so a WINE_SRC upgrade would otherwise desync the symlinked
        # wineserver from the copied-and-patched wine.
        cp "$f" "$DEST/bin/"
    else
        ln -s "$f" "$DEST/bin/"
    fi
done

for f in "$WINE_SRC/$unixdir"/*; do
    case "$(basename "$f")" in
        ntdll.so|wine|wine-preloader) cp "$f" "$DEST/$unixdir/" ;;
        *) ln -s "$f" "$DEST/$unixdir/" ;;
    esac
done

for f in "$WINE_SRC/$pedir"/*; do
    ln -s "$f" "$DEST/$pedir/"
done

replace() {
    if [ ! -f "$1" ]; then
        echo "missing $1" >&2
        exit 1
    fi
    rm "$2"
    cp "$1" "$2"
}

for module in $PATCHED_MODULES; do
    replace "$WINE_BUILD/dlls/${module%.dll}/x86_64-windows/$module" "$DEST/$pedir/$module"
done

for lib in $PATCHED_UNIXLIBS; do
    replace "$WINE_BUILD/dlls/$lib" "$DEST/$unixdir/$(basename "$lib")"
done

echo "Wine overlay created in $DEST"
