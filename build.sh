#!/bin/sh
# Build the patched Wine modules that ROUVY needs, and create wine-overlay.
#
# Only the modules that differ from the installed Wine are built, so the
# source has to be exactly the version of Wine that is installed.
set -e

dir="$(dirname "$(readlink -f "$0")")"
WINE_SRC="${WINE_SRC:-/opt/wine-devel}"
WINE_DIR="${WINE_DIR:-$dir/wine}"
WINE_REPO="${WINE_REPO:-https://github.com/jelmer/wine.git}"
WINE_BRANCH="${WINE_BRANCH:-rouvy-fixes}"
MODULES="dnsapi msvcp140 winebth.sys windows.devices.bluetooth"

if [ ! -x "$WINE_SRC/bin/wine" ]; then
    echo "no Wine installation in $WINE_SRC; install winehq-devel or set WINE_SRC" >&2
    exit 1
fi

if [ ! -d "$WINE_DIR" ]; then
    git clone --depth 1 --branch "$WINE_BRANCH" "$WINE_REPO" "$WINE_DIR"
fi

installed="$("$WINE_SRC/bin/wine" --version | cut -d' ' -f1)"
source="wine-$(sed -n 's/^Wine version //p' "$WINE_DIR/VERSION")"
if [ "$installed" != "$source" ]; then
    echo "the installed Wine is $installed, but $WINE_DIR is $source" >&2
    exit 1
fi

# Wine can use clang to build PE modules, but looks for ld.lld, which Debian
# only puts in the versioned LLVM directory.
if ! command -v x86_64-w64-mingw32-gcc >/dev/null && ! command -v ld.lld >/dev/null; then
    llvm_bin=""
    for d in $(ls -d /usr/lib/llvm-*/bin 2>/dev/null | sort -V); do
        if [ -x "$d/clang" ] && [ -x "$d/ld.lld" ]; then
            llvm_bin="$d"
        fi
    done
    if [ -z "$llvm_bin" ]; then
        echo "no PE cross compiler found; install clang and lld, or gcc-mingw-w64-x86-64" >&2
        exit 1
    fi
    PATH="$llvm_bin:$PATH"
    export PATH
fi

mkdir -p "$WINE_DIR/build"
cd "$WINE_DIR/build"

configured() {
    [ -f Makefile ] && grep -q '^#define SONAME_LIBDBUS_1 ' include/config.h &&
        grep -q '^PE_ARCHS = .*x86_64' Makefile
}

if ! configured; then
    ../configure --enable-win64 --disable-tests --without-x --without-freetype
fi
if ! configured; then
    echo "Wine was configured without D-Bus support or without a PE cross compiler;" >&2
    echo "winebth needs libdbus-1-dev. See $WINE_DIR/build/config.log" >&2
    exit 1
fi

targets=""
for module in $MODULES; do
    targets="$targets dlls/$module/all"
done
# shellcheck disable=SC2086
make -j"$(nproc)" $targets

WINE_SRC="$WINE_SRC" WINE_BUILD="$WINE_DIR/build" "$dir/make-wine-overlay.sh" "$@"
