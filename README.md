# ROUVY on Linux with Wine

ROUVY needs a few changes to Wine that are not upstream at the moment: a
small fix to dnsapi that stops it from crashing shortly after startup
(see [Wine bug 60211](https://bugs.winehq.org/show_bug.cgi?id=60211)), and
Bluetooth LE support so that it can find and talk to trainers and sensors.

This repository builds a Podman image that bundles winehq-devel, those
patched builtin modules (from the `rouvy-fixes` branch of
https://github.com/jelmer/wine, tracked here as a submodule), and a
freshly installed ROUVY, and ships a wrapper to run it with host access
to the display, audio and Bluetooth.

## Requirements

* Podman
* BlueZ on the host, with bluetoothd running
* For NVIDIA GPUs: `nvidia-container-toolkit` with CDI configured
  (`sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`).
  Mesa-based GPUs are picked up via `/dev/dri` automatically.

## Usage

Pull a published build:

    podman pull ghcr.io/jelmer/rouvy
    ./run-rouvy.sh

Or build locally:

    git submodule update --init --depth 1 container/wine
    podman build -f container/Containerfile -t ghcr.io/jelmer/rouvy .
    ./run-rouvy.sh

The first run seeds the `rouvy-data` volume from the ROUVY install baked
into the image; later runs reuse it, so your login and downloaded routes
survive image rebuilds. `run-rouvy.sh` wires up the host X
display, PulseAudio, the system D-Bus (BlueZ needs the system bus to see
trainers), and the GPU, and uses host networking.

Rebuild the image to pick up a new ROUVY release or Wine patches; the
`rouvy-data` volume is not touched by a rebuild.

## Status

Tested with a Wahoo KICKR: it is found, pairs as power meter, cadence
sensor and controllable trainer, and reports power. Heart rate monitors
and resistance control during a ride have not been verified yet.

Connecting can take 10 to 20 seconds if the signal is weak.
