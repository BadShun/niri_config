#!/bin/sh
set -eu

if fcitx5-remote --check >/dev/null 2>&1; then
    # A nested Niri session can share Fcitx with its host desktop.
    busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 \
        OpenWaylandConnection s "$WAYLAND_DISPLAY"
    if [ -n "${DISPLAY:-}" ]; then
        fcitx5-remote -x
    fi
else
    exec fcitx5
fi
