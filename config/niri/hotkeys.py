"""Show the shortcuts from this desktop's Niri configuration."""

import json
import os
from pathlib import Path
import subprocess

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, Gtk, GtkLayerShell


GROUPS = (
    ("应用与系统", (
        ("打开终端", "Mod + T"),
        ("搜索应用", "Mod + D"),
        ("关闭当前窗口", "Mod + Q"),
        ("区域截图", "Print"),
        ("退出 Niri", "Mod + Shift + E"),
    )),
    ("焦点切换", (
        ("切换左右相邻列", "Mod + ← / →"),
        ("切换同列上下窗口", "Mod + ↑ / ↓"),
        ("切换平铺与浮动焦点", "Mod + Shift + V"),
        ("跳到第一列或最后一列", "Mod + Home / End"),
        ("打开工作区总览", "Mod + O"),
    )),
    ("窗口布局", (
        ("左右移动当前列", "Mod + Ctrl + ← / →"),
        ("合并或拆出窗口", "Mod + [ / ]"),
        ("切换预设列宽", "Mod + R"),
        ("最大化当前列", "Mod + F"),
        ("全屏当前窗口", "Mod + Shift + F"),
        ("切换窗口浮动", "Mod + V"),
    )),
    ("工作区", (
        ("切换工作区", "Mod + I / U"),
        ("跳到指定工作区", "Mod + 1–9"),
        ("移动列到相邻工作区", "Mod + Ctrl + I / U"),
        ("移动列到指定工作区", "Mod + Ctrl + 1–9"),
        ("将当前工作区上移或下移", "Mod + Shift + I / U"),
    )),
)


def text_label(text, style=None):
    widget = Gtk.Label(label=text, xalign=0)
    if style:
        widget.get_style_context().add_class(style)
    return widget


def shortcut_card(title, shortcuts, modifier):
    card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    card.get_style_context().add_class("card")
    card.pack_start(text_label(title, "section"), False, False, 2)
    for description, binding in shortcuts:
        row = Gtk.Box(spacing=12)
        row.pack_start(text_label(description), True, True, 0)
        row.pack_end(text_label(binding.replace("Mod", modifier), "key"), False, False, 0)
        card.pack_start(row, False, False, 0)
    return card


def show_panel(app):
    if (current_window := app.get_active_window()) is not None:
        current_window.destroy()
        return

    output = json.loads(subprocess.check_output(
        ["niri", "msg", "--json", "focused-output"], text=True, timeout=2,
    )) or {}
    size = output.get("logical") or {}
    available_width = size.get("width", 1280)
    available_height = size.get("height", 800)
    columns = 2 if available_width >= 860 else 1
    modifier = "Alt" if output.get("name") == "winit" else "Super"

    window = Gtk.ApplicationWindow(application=app, title="Niri 快捷键")
    window.set_name("niri-hotkeys")
    window.set_decorated(False)
    window.set_default_size(min(816, available_width - 32), -1)
    window.set_visual(window.get_screen().get_rgba_visual())
    GtkLayerShell.init_for_window(window)
    GtkLayerShell.set_namespace(window, "niri-hotkeys")
    GtkLayerShell.set_layer(window, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_exclusive_zone(window, -1)
    GtkLayerShell.set_keyboard_mode(window, GtkLayerShell.KeyboardMode.EXCLUSIVE)

    def close_on_escape(_window, event):
        if event.keyval == Gdk.KEY_Escape:
            window.destroy()
            return True
        return False

    window.connect("key-press-event", close_on_escape)

    panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    panel.get_style_context().add_class("panel")

    grid = Gtk.Grid(column_spacing=12, row_spacing=12, column_homogeneous=True)
    for index, (title, shortcuts) in enumerate(GROUPS):
        card = shortcut_card(title, shortcuts, modifier)
        grid.attach(card, index % columns, index // columns, 1, 1)

    scroller = Gtk.ScrolledWindow()
    scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
    scroller.add(grid)
    panel.pack_start(scroller, True, True, 0)
    window.add(panel)

    css = Gtk.CssProvider()
    css.load_from_path(str(Path(__file__).with_name("hotkeys.css")))
    Gtk.StyleContext.add_provider_for_screen(
        window.get_screen(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
    )
    grid.show_all()
    _, natural_height = grid.get_preferred_height()
    scroller.set_min_content_height(min(natural_height, max(160, available_height - 140)))
    window.show_all()


if __name__ == "__main__":
    instance = Path(os.environ.get("NIRI_SOCKET", "")).stem.rsplit(".", 1)[-1]
    app = Gtk.Application(application_id=f"org.niri.Hotkeys.s{instance if instance.isdigit() else '0'}")
    app.connect("activate", show_panel)
    raise SystemExit(app.run())
