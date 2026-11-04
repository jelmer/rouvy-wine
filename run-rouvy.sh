#!/bin/sh
# Run ROUVY from the rouvy-wine container with host access to display,
# audio and Bluetooth. User data lives in the 'rouvy-data' podman volume.
set -e

IMAGE="${ROUVY_IMAGE:-ghcr.io/jelmer/rouvy-wine}"
VOLUME="${ROUVY_VOLUME:-rouvy-data}"

if ! podman volume exists "$VOLUME" 2>/dev/null; then
    podman volume create "$VOLUME" >/dev/null
fi

# Allow local X clients from this user. Harmless if xhost or X are absent.
if command -v xhost >/dev/null 2>&1; then
    xhost +SI:localuser:"$(id -un)" >/dev/null 2>&1 || true
fi

PULSE_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/pulse/native"
pulse_args=""
if [ -S "$PULSE_SOCK" ]; then
    pulse_args="-e PULSE_SERVER=unix:/run/pulse/native -v $PULSE_SOCK:/run/pulse/native"
fi

# BlueZ runs on the system D-Bus; expose it read-write.
dbus_args="-v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket"

# Prefer the NVIDIA CDI device if present; otherwise fall back to /dev/dri
# for Mesa-based GPUs. The CDI file is produced by `nvidia-ctk cdi generate`;
# regenerate it after a driver upgrade.
gpu_args="--device /dev/dri"
if [ -f /etc/cdi/nvidia.yaml ] || [ -f /var/run/cdi/nvidia.yaml ]; then
    gpu_args="--device nvidia.com/gpu=all"
fi

# shellcheck disable=SC2086
exec podman run --rm -it \
    --name rouvy \
    --network host \
    -e DISPLAY="$DISPLAY" \
    -e XDG_RUNTIME_DIR=/run/user/0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    $dbus_args \
    $pulse_args \
    $gpu_args \
    -v "$VOLUME":/data \
    "$IMAGE" "$@"
