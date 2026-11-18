#!/usr/bin/env bash
set -euo pipefail

if [[ ${1-} == --help ]]; then
    printf '%s\n' '用法：./install-deps.sh' '通过 Fedora 软件源安装 Niri 和桌面组件。'
    exit 0
fi
if (( $# != 0 )); then
    printf '未知参数：%s\n' "$1" >&2
    exit 2
fi

. /etc/os-release
if [[ ${ID:-} != fedora ]] || ! command -v dnf >/dev/null; then
    printf '%s\n' '此脚本使用 Fedora 的 DNF。其他发行版的依赖见 README.md。' >&2
    exit 1
fi

packages=(
    niri waybar rofi alacritty swaybg swaylock
    xwayland-satellite xorg-x11-server-Xwayland xdg-desktop-portal-gtk
    fcitx5 fcitx5-rime brise fcitx5-gtk3 fcitx5-gtk4 fcitx5-qt5 fcitx5-qt6
    python3-gobject gtk-layer-shell util-linux
    fontconfig breeze-icon-theme google-noto-sans-fonts google-noto-sans-cjk-vf-fonts
    fontawesome-6-free-fonts
    pipewire-pulseaudio wireplumber playerctl brightnessctl
)

if (( EUID == 0 )); then
    dnf install -y "${packages[@]}"
else
    sudo dnf install -y "${packages[@]}"
fi
