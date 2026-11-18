#!/usr/bin/env bash
set -euo pipefail
umask 077

declare -A skipped=()
while (( $# > 0 )); do
    case $1 in
        --help)
            cat <<'EOF'
用法：./apply-config.sh [--skip-config 软件]…
安装当前用户的配置、壁纸和字体，并备份即将被替换的文件。

--skip-config 软件    保留该软件的配置。可重复指定。
可选软件：alacritty、fcitx5、rofi、waybar、xwaylandvideobridge
示例：./apply-config.sh --skip-config fcitx5 --skip-config alacritty
EOF
            exit 0
            ;;
        --skip-config)
            case ${2-} in
                alacritty|fcitx5|rofi|waybar|xwaylandvideobridge) skipped[$2]=1 ;;
                '') printf '%s\n' '--skip-config 需要一个软件名称。' >&2; exit 2 ;;
                *) printf '无法跳过此配置：%s\n' "$2" >&2; exit 2 ;;
            esac
            shift 2
            ;;
        *) printf '未知参数：%s\n' "$1" >&2; exit 2 ;;
    esac
done
if (( EUID == 0 )); then
    printf '%s\n' '请用运行桌面会话的用户执行 ./apply-config.sh。' >&2
    exit 1
fi

for command in niri fc-cache flock; do
    if ! command -v "$command" >/dev/null; then
        printf '找不到 %s，请先安装依赖。\n' "$command" >&2
        exit 1
    fi
done

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
state_dir=${XDG_STATE_HOME:-"$HOME/.local/state"}/niri-config
font_dir=fonts/niri-config/JetBrainsMono

mkdir -p -- "$state_dir"
exec 9>"$state_dir/install.lock"
flock 9

staging=$(mktemp -d)
backup=
pending=
modified=()

target_path() {
    case $1 in
        config/*) printf '%s/%s\n' "$config_home" "${1#config/}" ;;
        data/*) printf '%s/%s\n' "$data_home" "${1#data/}" ;;
    esac
}

cleanup() {
    local status=$? key target i
    trap - EXIT
    set +e
    if [[ -n $pending ]]; then
        rm -f -- "$pending"
    fi
    if (( status != 0 && ${#modified[@]} > 0 )); then
        for (( i=${#modified[@]}-1; i>=0; i-- )); do
            key=${modified[i]}
            target=$(target_path "$key")
            if [[ -n $backup && ( -e $backup/$key || -L $backup/$key ) ]]; then
                cp -aT --remove-destination -- "$backup/$key" "$target"
            else
                rm -f -- "$target"
            fi
        done
        printf '%s\n' '应用失败，已尝试恢复原配置。' >&2
    fi
    rm -rf -- "$staging"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cp -R -- "$repo/config" "$staging/config"
install -Dm644 -- "$repo/assets/wallpapers/dusk-mountains.png" "$staging/config/niri/wallpapers/dusk-mountains.png"
mkdir -p -- "$staging/data/$font_dir"
cp -- "$repo/assets/fonts/JetBrainsMono/"* "$staging/data/$font_dir/"

niri_config="$staging/config/niri/config.kdl"
if command -v systemd-detect-virt >/dev/null && [[ $(systemd-detect-virt --vm || true) == vmware ]]; then
    printf '\n' >> "$niri_config"
    cat "$staging/config/niri/vmware-cursor.kdl" >> "$niri_config"
fi

files=(
    config/niri/fcitx5-start.sh config/niri/hotkeys.py config/niri/hotkeys.css
    config/niri/wallpapers/dusk-mountains.png
    "data/$font_dir/JetBrainsMono[wght].ttf" "data/$font_dir/JetBrainsMono_Italic[wght].ttf"
    "data/$font_dir/OFL.txt"
)

if [[ -n ${skipped[waybar]-} ]]; then
    sed -i '/^spawn-sh-at-startup r#"exec waybar -c /c\spawn-at-startup "waybar"' "$niri_config"
else
    files+=(config/waybar/config.jsonc config/waybar/style.css)
fi
if [[ -n ${skipped[rofi]-} ]]; then
    sed -i -E 's/(\{ )spawn-sh r#"exec rofi -no-config -theme .* -show drun"#(; \})$/\1spawn "rofi" "-show" "drun"\2/' "$niri_config"
else
    files+=(config/rofi/niri-glass.rasi)
fi
if [[ -z ${skipped[alacritty]-} ]]; then
    files+=(config/alacritty/alacritty.toml)
fi
if [[ -z ${skipped[fcitx5]-} ]]; then
    files+=(config/fcitx5/config config/fcitx5/profile)
fi
if [[ -z ${skipped[xwaylandvideobridge]-} ]]; then
    files+=(config/autostart/org.kde.xwaylandvideobridge.desktop)
fi
files+=(config/niri/config.kdl)
niri validate -c "$niri_config"

changes=()
for key in "${files[@]}"; do
    target=$(target_path "$key")
    if [[ -e $target && ! -f $target && ! -L $target ]]; then
        printf '目标不是普通文件：%s\n' "$target" >&2
        exit 1
    fi
    if [[ ! -L $target && -f $target ]] && cmp -s -- "$staging/$key" "$target"; then
        continue
    fi
    changes+=("$key")
    if [[ -e $target || -L $target ]]; then
        if [[ -z $backup ]]; then
            mkdir -p -- "$state_dir/backups"
            backup=$(mktemp -d "$state_dir/backups/$(date +%Y%m%d-%H%M%S).XXXXXX")
        fi
        mkdir -p -- "$backup/$(dirname -- "$key")"
        cp -aT -- "$target" "$backup/$key"
    fi
done

for key in "${changes[@]}"; do
    target=$(target_path "$key")
    parent=$(dirname -- "$target")
    mkdir -p -- "$parent"
    pending=$(mktemp "$parent/.niri-config.XXXXXX")
    install -m 644 -- "$staging/$key" "$pending"
    modified+=("$key")
    mv -fT -- "$pending" "$target"
    pending=
done

fc-cache -f -- "$data_home/$font_dir"
printf '%s\n' '配置已应用。重新进入 Niri 会话即可加载启动项。'
if (( ${#skipped[@]} > 0 )); then
    printf '已保留 %s 的设置。\n' "${!skipped[@]}"
fi
if [[ -n $backup ]]; then
    printf '备份目录：%s\n' "$backup"
fi
