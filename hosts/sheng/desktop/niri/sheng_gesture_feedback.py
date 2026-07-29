#!/usr/bin/env python3

import math
import os
import socket

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell


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

        self.window = Gtk.Window()
        self.window.set_decorated(False)
        self.window.set_resizable(False)
        self.window.set_default_size(*WINDOW_SIZES[edge])
        self.window.set_opacity(0)

        Gtk4LayerShell.init_for_window(self.window)
        Gtk4LayerShell.set_namespace(self.window, "sheng-gesture-feedback")
        Gtk4LayerShell.set_layer(self.window, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(
            self.window, Gtk4LayerShell.KeyboardMode.NONE
        )
        Gtk4LayerShell.set_exclusive_zone(self.window, 0)
        Gtk4LayerShell.set_anchor(self.window, EDGE_MAP[edge], True)

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

    def show(self, icon_name):
        if self.timeout_id:
            GLib.source_remove(self.timeout_id)
            self.timeout_id = 0

        self.icon.set_from_icon_name(icon_name)
        self.started_us = GLib.get_monotonic_time()
        self.window.set_opacity(0)
        Gtk4LayerShell.set_margin(self.window, EDGE_MAP[self.edge], 2)
        self.window.present()
        self.timeout_id = GLib.timeout_add(16, self.animate)

    def animate(self):
        elapsed_ms = (GLib.get_monotonic_time() - self.started_us) / 1000
        progress = min(elapsed_ms / 460, 1)

        if progress < 0.28:
            phase = progress / 0.28
            opacity = 1 - pow(1 - phase, 3)
        else:
            phase = (progress - 0.28) / 0.72
            opacity = 1 - phase * phase

        margin = round(2 + 16 * math.sin(math.pi * progress))
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
              background: rgba(8, 10, 35, 0.94);
              border: 2px solid rgba(154, 148, 255, 0.86);
              border-radius: 8px;
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
              color: #fff27a;
            }
            """
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

    def on_message(self, _fd, _condition):
        try:
            event = self.sock.recv(128).decode("ascii", errors="ignore").strip()
        except BlockingIOError:
            return GLib.SOURCE_CONTINUE

        target = EVENTS.get(event)
        if target:
            edge, icon_name = target
            self.indicators[edge].show(icon_name)
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
