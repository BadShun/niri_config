# Niri 桌面配置

这套配置包含「暮色山峦」壁纸、Waybar 状态栏、Rofi 毛玻璃启动器、Alacritty 终端、Niri 快捷键面板，以及 Fcitx5 和 Rime 中文输入。

## 在新电脑上使用

在 Fedora 上运行这两条脚本。第一条通过 DNF 安装 Niri 和依赖，第二条以当前用户身份应用配置。

```sh
git clone https://github.com/BadShun/niri_config.git
cd niri_config
./install-deps.sh
./apply-config.sh
```

如果软件已经装好，直接运行 `./apply-config.sh`。以 Fedora 44 的软件包为准，使用 Niri 26.04 或兼容版本和支持 Wayland 的 Rofi 2.x。其他发行版可以按其软件包名称安装 [同样的依赖](install-deps.sh)，再运行配置脚本。

应用后在登录界面的会话菜单选择 **Niri**。已有桌面会话也可以从终端运行 `niri` 来预览窗口模式。

## 配置内容

- Niri 窗口四角圆角、Chrome 半宽打开、终端毛玻璃，以及窗口模式与独立会话使用不同修饰键的快捷键面板。VMware 客户机额外应用软件光标设置。
- Waybar 显示工作区、窗口标题、时钟、托盘、网络和音量。Rofi 初次打开只有一行带 `>` 的输入框，输入后显示匹配项。
- Alacritty 使用 JetBrains Mono、半透明背景和内边距。仓库内含普通及斜体可变字体，安装到当前用户的字体目录。
- Fcitx5 在 Niri 中自动启动或连接现有实例，预置 Rime，使用 `Ctrl+Space` 切换中文输入。XWayland Video Bridge 的用户自启动项已禁用。

| 操作 | KDE 窗口模式 | 独立 Niri 会话 |
| --- | --- | --- |
| 打开终端 | `Alt+T` | `Super+T` |
| 搜索应用 | `Alt+D` | `Super+D` |
| 查看快捷键 | `Alt+Shift+/` | `Super+Shift+/` |

配置默认写入 `~/.config` 和 `~/.local/share`，并支持 XDG 自定义目录。应用脚本会将需要替换的文件备份到 `~/.local/state/niri-config/backups`。备份按 `config` 和 `data` 分别对应配置与数据目录。脚本涵盖桌面配置，Chrome 账户数据和 Rime 用户词库需由各自的工具迁移。

`config/niri/config.kdl` 派生自 [Niri 的默认配置](https://github.com/niri-wm/niri/blob/49fc6117/resources/default-config.kdl)，Niri 的授权见 [LICENSE](LICENSE)。[JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) 字体的授权随字体目录一起提供。 [SIL Open Font License](assets/fonts/JetBrainsMono/OFL.txt)
