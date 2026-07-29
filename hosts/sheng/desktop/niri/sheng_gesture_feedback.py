#!/usr/bin/env python3

import math
import json
import os
import socket

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell  # noqa: E402


EVENTS = {
    "back": ("left", "go-next-symbolic"),
    "back-left": ("left", "go-next-symbolic"),
    "back-right": ("right", "go-previous-symbolic"),
    "home": ("bottom", "go-home-symbolic"),
    "recents": ("bottom", "view-grid-symbolic"),
    "overview": ("bottom", "view-grid-symbolic"),
    "column-left": ("bottom", "go-previous-symbolic"),
    "column-right": ("bottom", "go-next-symbolic"),
    "control-center": ("top", "open-menu-symbolic"),
    "fullscreen": ("bottom", "view-fullscreen-symbolic"),
    "maximize": ("bottom", "view-restore-symbolic"),
    "close": ("bottom", "window-close-symbolic"),
}

WINDOW_SIZES = {
    "left": (64, 112),
    "right": (64, 112),
    "top": (112, 56),
    "bottom": (112, 56),
}

EDGE_MAP = {
    "left": Gtk4LayerShell.Edge.LEFT,
    "right": Gtk4LayerShell.Edge.RIGHT,
    "top": Gtk4LayerShell.Edge.TOP,
    "bottom": Gtk4LayerShell.Edge.BOTTOM,
}


class Indicator:
    def __init__(self, edge):
        self.edge = edge
        self.timeout_id = 0
        self.started_us = 0
        self.start_margin = 2
        self.start_opacity = 0
        self.progress = 0
        self.phase = "idle"

        self.window = Gtk.Window()
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        self.window.set_default_size(*WINDOW_SIZES[edge])
        self.window.set_opacity(0)

        Gtk4LayerShell.init_for_window(self.window)
        Gtk4LayerShell.set_namespace(self.window, "sheng-gesture-feedback")
        Gtk4LayerShell.set_layer(self.window, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(self.window, Gtk4LayerShell.KeyboardMode.NONE)
        Gtk4LayerShell.set_exclusive_zone(self.window, 0)
        Gtk4LayerShell.set_anchor(self.window, EDGE_MAP[edge], True)
        if edge in ("left", "right"):
            Gtk4LayerShell.set_anchor(self.window, Gtk4LayerShell.Edge.TOP, True)
        else:
            Gtk4LayerShell.set_anchor(self.window, Gtk4LayerShell.Edge.LEFT, True)

        self.frame = Gtk.Box()
        self.frame.add_css_class("gesture-feedback")
        self.frame.add_css_class(f"gesture-feedback-{edge}")
        self.frame.set_halign(Gtk.Align.CENTER)
        self.frame.set_valign(Gtk.Align.CENTER)

        self.icon = Gtk.Image()
        self.icon.add_css_class("gesture-feedback-icon")
        self.icon.set_pixel_size(30)
        self.frame.append(self.icon)
        self.window.set_child(self.frame)

    def set_position(self, position):
        display = Gdk.Display.get_default()
        monitors = display.get_monitors()
        if monitors.get_n_items() == 0:
            return
        geometry = monitors.get_item(0).get_geometry()
        if self.edge in ("left", "right"):
            span = max(1, geometry.height - WINDOW_SIZES[self.edge][1])
            margin = round(16 + position * max(0, span - 32))
            Gtk4LayerShell.set_margin(self.window, Gtk4LayerShell.Edge.TOP, margin)
        else:
            span = max(1, geometry.width - WINDOW_SIZES[self.edge][0])
            margin = round(16 + position * max(0, span - 32))
            Gtk4LayerShell.set_margin(self.window, Gtk4LayerShell.Edge.LEFT, margin)

    def apply_progress(self, progress):
        self.progress = max(0, min(progress, 1))
        eased = 1 - pow(1 - self.progress, 3)
        margin = round(2 + 20 * eased)
        Gtk4LayerShell.set_margin(self.window, EDGE_MAP[self.edge], margin)
        self.window.set_opacity(0.24 + 0.76 * eased)
        self.icon.set_pixel_size(round(24 + 8 * eased))
        if self.progress >= 1:
            self.frame.add_css_class("gesture-feedback-ready")
        else:
            self.frame.remove_css_class("gesture-feedback-ready")

    def update(self, icon_name, progress, position):
        if self.timeout_id:
            GLib.source_remove(self.timeout_id)
            self.timeout_id = 0

        self.icon.set_from_icon_name(icon_name)
        self.set_position(position)
        self.window.present()
        self.phase = "tracking"
        self.apply_progress(progress)

    def finish(self, committed):
        if self.timeout_id:
            GLib.source_remove(self.timeout_id)
        self.phase = "commit" if committed else "cancel"
        self.start_margin = round(2 + 20 * self.progress)
        self.start_opacity = self.window.get_opacity()
        self.started_us = GLib.get_monotonic_time()
        self.timeout_id = GLib.timeout_add(16, self.animate)

    def animate(self):
        elapsed_ms = (GLib.get_monotonic_time() - self.started_us) / 1000
        duration = 280 if self.phase == "commit" else 190
        progress = min(elapsed_ms / duration, 1)
        eased = 1 - pow(1 - progress, 3)

        if self.phase == "commit":
            margin = self.start_margin + round(10 * math.sin(math.pi * progress))
            opacity = self.start_opacity * (1 - progress * progress)
        else:
            margin = round(self.start_margin * (1 - eased))
            opacity = self.start_opacity * (1 - eased)
        Gtk4LayerShell.set_margin(self.window, EDGE_MAP[self.edge], margin)
        self.window.set_opacity(max(0, min(opacity, 1)))

        if progress >= 1:
            self.window.set_visible(False)
            self.timeout_id = 0
            return GLib.SOURCE_REMOVE
        return GLib.SOURCE_CONTINUE


class FeedbackApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="io.github.dotredstone.ShengGestureFeedback")
        self.indicators = {}
        self.sock = None
        self.socket_path = os.path.join(
            os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"),
            "sheng-niri-gesture-feedback.sock",
        )

    def do_activate(self):
        if self.indicators:
            return

        provider = Gtk.CssProvider()
        provider.load_from_string(
            """
            window {
              background: transparent;
            }
            .gesture-feedback {
              min-width: 48px;
              min-height: 48px;
              background: @surface;
              border: 2px solid @outline;
              border-radius: 8px;
            }
            .gesture-feedback-ready {
              background: @primary;
              border-color: @primary;
            }
            .gesture-feedback-left {
              border-left-width: 0;
            }
            .gesture-feedback-right {
              border-right-width: 0;
            }
            .gesture-feedback-top {
              border-top-width: 0;
            }
            .gesture-feedback-bottom {
              border-bottom-width: 0;
            }
            .gesture-feedback-icon {
              color: @on_surface;
            }
            .gesture-feedback-ready .gesture-feedback-icon {
              color: @on_primary;
            }
            """.replace(
                "@surface", self.theme_color("mSurface", "rgba(8, 10, 35, 0.94)")
            )
            .replace("@outline", self.theme_color("mOutline", "#9a94ff"))
            .replace("@primary", self.theme_color("mPrimary", "#fff27a"))
            .replace("@on_surface", self.theme_color("mOnSurface", "#f4f2ff"))
            .replace("@on_primary", self.theme_color("mOnPrimary", "#211f2a"))
        )
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        self.indicators = {
            edge: Indicator(edge) for edge in ("left", "right", "top", "bottom")
        }
        for indicator in self.indicators.values():
            indicator.window.set_application(self)

        try:
            os.unlink(self.socket_path)
        except FileNotFoundError:
            pass

        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.sock.bind(self.socket_path)
        os.chmod(self.socket_path, 0o600)
        self.sock.setblocking(False)
        GLib.io_add_watch(self.sock.fileno(), GLib.IO_IN, self.on_message)
        self.hold()

    def theme_color(self, name, fallback):
        path = os.path.expanduser("~/.config/noctalia/colors.json")
        try:
            with open(path, encoding="utf-8") as colors_file:
                colors = json.load(colors_file)
            return colors.get("dark", {}).get(name, fallback)
        except (OSError, ValueError, TypeError):
            return fallback

    def on_message(self, _fd, _condition):
        try:
            message = self.sock.recv(512).decode("ascii", errors="ignore").strip()
        except BlockingIOError:
            return GLib.SOURCE_CONTINUE

        try:
            payload = json.loads(message)
        except ValueError:
            payload = None

        if isinstance(payload, dict):
            event = payload.get("event", "")
            target = EVENTS.get(event)
            if not target:
                return GLib.SOURCE_CONTINUE
            edge, icon_name = target
            indicator = self.indicators[edge]
            phase = payload.get("phase", "update")
            if phase in ("begin", "update"):
                indicator.update(
                    icon_name,
                    float(payload.get("progress", 0)),
                    float(payload.get("position", 0.5)),
                )
            elif phase == "commit":
                indicator.update(icon_name, 1, float(payload.get("position", 0.5)))
                indicator.finish(True)
            elif phase == "cancel":
                indicator.finish(False)
            return GLib.SOURCE_CONTINUE

        event = message
        target = EVENTS.get(event)
        if target:
            edge, icon_name = target
            indicator = self.indicators[edge]
            indicator.update(icon_name, 1, 0.5)
            indicator.finish(True)
        return GLib.SOURCE_CONTINUE

    def do_shutdown(self):
        if self.sock:
            self.sock.close()
        try:
            os.unlink(self.socket_path)
        except FileNotFoundError:
            pass
        Gtk.Application.do_shutdown(self)


if __name__ == "__main__":
    FeedbackApp().run()
