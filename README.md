# ROUVY on Linux with Wine

ROUVY needs a few changes to Wine that are not upstream at the moment: a
small fix to dnsapi that stops it from crashing shortly after startup
(see [Wine bug 60211](https://bugs.winehq.org/show_bug.cgi?id=60211)), and
Bluetooth LE support so that it can find and talk to trainers and sensors.

These scripts build the patched modules from the `rouvy-fixes` branch of
https://github.com/jelmer/wine and run ROUVY with them.

## Requirements

* winehq-devel 11.19 from the WineHQ repository, installed in
  `/opt/wine-devel`. Only the modules that changed are built, so the
  installed Wine has to be exactly this version.
* BlueZ, with bluetoothd running
* git, make, gcc, flex, bison and libdbus-1-dev
* clang and lld to build the Windows side of the modules.
  gcc-mingw-w64-x86-64 should work too, but I haven't tried it.

## Usage

    ./download-rouvy.sh
    wine Rouvy_Installer_*.exe
    ./build.sh
    ./run-rouvy.sh

`build.sh` clones Wine into `wine/` and creates `wine-overlay/`, which is
the installed Wine with the patched modules swapped in. Wine looks for its
own modules before anything in `WINEDLLPATH`, so they can't simply be put
in a directory on the side.

`run-rouvy.sh` has to be used to start ROUVY; plain `wine` still runs the
unpatched modules. If another Wine program is already running, close it
and run `wine-overlay/bin/wineserver -k` first, since the Bluetooth driver
is only loaded once per wineserver.

After changing the Wine source, run `build.sh` again.

## Container

`Containerfile` builds a Podman image that bundles winehq-devel, the
patched Wine overlay and a freshly installed ROUVY. User data (login,
settings, downloaded routes) lives in a mounted volume so the same image
can be shared.

    podman build -t ghcr.io/jelmer/rouvy-wine .
    ./run-rouvy-container.sh

Published builds live at `ghcr.io/jelmer/rouvy-wine`; `podman pull` works
instead of building locally.

The first run seeds the `rouvy-data` volume from the ROUVY install baked
into the image; later runs reuse it. `run-rouvy-container.sh` wires up
the host X display, PulseAudio and the system D-Bus (BlueZ needs the
system bus to see trainers), and uses host networking.

Rebuild the image to pick up a new ROUVY release or Wine patches; the
`rouvy-data` volume is not touched by a rebuild.

## Status

Tested with a Wahoo KICKR: it is found, pairs as power meter, cadence
sensor and controllable trainer, and reports power. Heart rate monitors
and resistance control during a ride have not been verified yet.

Connecting can take 10 to 20 seconds if the signal is weak.
