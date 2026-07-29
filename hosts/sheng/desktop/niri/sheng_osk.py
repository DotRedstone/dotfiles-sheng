#!/usr/bin/env python3
# ruff: noqa: E402, F722, F821

import json
import os
import time
from pathlib import Path

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from dbus_next import Message, MessageFlag, MessageType
from dbus_next.constants import RequestNameReply
from dbus_next.glib import MessageBus
from dbus_next.service import ServiceInterface, method
from gi.repository import Gdk, Gio, GLib, Gtk, Gtk4LayerShell


VK_NAME = "org.fcitx.Fcitx5.VirtualKeyboard"
VK_PATH = "/org/fcitx/virtualkeyboard/impanel"
VK_INTERFACE = "org.fcitx.Fcitx5.VirtualKeyboard1"

BACKEND_NAME = "org.fcitx.Fcitx5.VirtualKeyboardBackend"
BACKEND_PATH = "/virtualkeyboard"
BACKEND_INTERFACE = "org.fcitx.Fcitx5.VirtualKeyboardBackend1"

FCITX_NAME = "org.fcitx.Fcitx5"
FCITX_PATH = "/virtualkeyboard"
FCITX_INTERFACE = "org.fcitx.Fcitx.VirtualKeyboard1"
CONTROLLER_PATH = "/controller"
CONTROLLER_INTERFACE = "org.fcitx.Fcitx.Controller1"

SHIFT_STATE = 1
CTRL_STATE = 4

MIN_WIDTH = 760
MAX_WIDTH = 1420
MIN_HEIGHT = 360
MAX_HEIGHT = 620
DEFAULT_WIDTH = 1160
DEFAULT_HEIGHT = 450
EDGE_MARGIN = 18


CSS = b"""
window.sheng-osk {
  background: transparent;
  color: #f4f2ff;
}

.keyboard-shell {
  background: rgba(9, 9, 34, 0.98);
  border: 1px solid #45436f;
  border-radius: 8px;
  box-shadow: 0 14px 38px rgba(0, 0, 12, 0.52);
  padding: 10px;
}

.drag-handle {
  min-height: 38px;
  color: #cbc7dc;
  padding: 0 8px;
}

.drag-title {
  font-size: 14px;
  font-weight: 600;
}

.drag-hint, .im-label {
  color: #a9a5c1;
  font-size: 13px;
}

.candidate-bar {
  min-height: 48px;
  background: #11112f;
  border: 1px solid #36345c;
  border-radius: 6px;
  padding: 3px 5px;
}

.preedit {
  color: #f5df8e;
  font-size: 17px;
  font-weight: 600;
  padding: 0 8px;
}

button {
  border-radius: 6px;
  border: 1px solid #45436c;
  background: #1a193c;
  color: #f5f3ff;
  box-shadow: none;
}

button:hover, button:focus {
  background: #292750;
  border-color: #6d6999;
}

button:active {
  background: #353160;
}

button.key {
  min-height: 54px;
  font-size: 19px;
  font-weight: 500;
}

button.special-key {
  background: #141431;
  color: #d9d5e8;
}

button.active-key {
  background: #f3df91;
  border-color: #fff0b0;
  color: #211f2a;
}

button.candidate {
  min-height: 38px;
  min-width: 64px;
  padding: 2px 12px;
  background: transparent;
  border-color: transparent;
  font-size: 17px;
}

button.candidate:selected, button.candidate.current {
  background: #f3df91;
  border-color: #fff0b0;
  color: #211f2a;
}

button.flat-control {
  min-height: 34px;
  min-width: 42px;
  background: transparent;
  border-color: transparent;
}

.resize-edge {
  background: transparent;
}

.resize-edge.horizontal {
  min-height: 24px;
}

.resize-edge.vertical {
  min-width: 24px;
}

.resize-indicator {
  background: rgba(243, 223, 145, 0.72);
  border-radius: 999px;
}

.resize-indicator.horizontal {
  min-width: 82px;
  min-height: 3px;
}

.resize-indicator.vertical {
  min-width: 3px;
  min-height: 82px;
}

.resize-edge.corner {
  min-width: 36px;
  min-height: 36px;
}

.resize-edge.top-left {
  border-top: 3px solid #f3df91;
  border-left: 3px solid #f3df91;
  border-radius: 7px 0 0 0;
}

.resize-edge.top-right {
  border-top: 3px solid #f3df91;
  border-right: 3px solid #f3df91;
  border-radius: 0 7px 0 0;
}

.resize-edge.bottom-left {
  border-bottom: 3px solid #f3df91;
  border-left: 3px solid #f3df91;
  border-radius: 0 0 0 7px;
}

.resize-edge.bottom-right {
  border-right: 3px solid #f3df91;
  border-bottom: 3px solid #f3df91;
  border-radius: 0 0 7px 0;
}
"""


LETTER_ROWS = [
    list("qwertyuiop"),
    list("asdfghjkl"),
    list("zxcvbnm"),
]

SYMBOL_ROWS = [
    list("1234567890"),
    ["@", "#", "$", "%", "&", "-", "+", "(", ")"],
    ["!", '"', "'", ":", ";", "/", "?"],
]

MORE_SYMBOL_ROWS = [
    ["~", "`", "_", "=", "[", "]", "{", "}", "\\", "|"],
    ["<", ">", "^", "*", ":", ";", "'", '"', "?"],
    ["@", "#", "$", "%", "&", "+", "/"],
]


def clamp(value, low, high):
    return max(low, min(value, high))


class FcitxVirtualKeyboard(ServiceInterface):
    def __init__(self, application):
        super().__init__(VK_INTERFACE)
        self.application = application

    @method()
    def ShowVirtualKeyboard(self):
        if not self.application.priming:
            GLib.idle_add(self.application.show_keyboard, "focus")

    @method()
    def HideVirtualKeyboard(self):
        if not self.application.consume_transient_hide():
            GLib.idle_add(self.application.hide_keyboard, "focus")

    @method()
    def UpdatePreeditCaret(self, caret: "i"):
        GLib.idle_add(self.application.set_preedit_caret, caret)

    @method()
    def UpdatePreeditArea(self, text: "s"):
        GLib.idle_add(self.application.set_preedit, text)

    @method()
    def UpdateCandidateArea(
        self,
        candidates: "as",
        has_previous: "b",
        has_next: "b",
        page: "i",
        cursor: "i",
    ):
        GLib.idle_add(
            self.application.set_candidates,
            candidates,
            has_previous,
            has_next,
            page,
            cursor,
        )

    @method()
    def NotifyIMActivated(self, unique_name: "s"):
        GLib.idle_add(self.application.set_input_method, unique_name)

    @method()
    def NotifyIMDeactivated(self, unique_name: "s"):
        GLib.idle_add(self.application.set_input_method, "")

    @method()
    def NotifyIMListChanged(self):
        GLib.idle_add(self.application.set_input_method, "")


class ShengOsk(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id="io.github.DotRedstone.ShengOsk",
            flags=Gio.ApplicationFlags.NON_UNIQUE,
        )
        self.window = None
        self.shell = None
        self.bus = None
        self.preedit_label = None
        self.candidate_box = None
        self.previous_button = None
        self.next_button = None
        self.input_method_label = None
        self.language_button = None
        self.adjust_button = None
        self.drag_hint = None
        self.key_area = None
        self.shift_button = None
        self.layer_button = None
        self.layer = "letters"
        self.symbol_page = 0
        self.shift_mode = "off"
        self.last_shift_tap = 0.0
        self.preedit = ""
        self.preedit_caret = -1
        self.candidates = []
        self.candidate_cursor = -1
        self.has_previous = False
        self.has_next = False
        self.page = -1
        self.geometry = self.load_geometry()
        self.drag_origin = (0, 0)
        self.resize_origin = None
        self.resize_direction = ""
        self.resize_edges = []
        self.adjusting = False
        self.input_method_active = False
        self.current_input_method = ""
        self.held = False
        self.priming = False
        self.primed = False
        self.prime_attempts = 0
        self.ignore_hide_token = 0

    @property
    def state_path(self):
        state_home = os.environ.get(
            "XDG_STATE_HOME", str(Path.home() / ".local" / "state")
        )
        return Path(state_home) / "sheng-osk" / "geometry.json"

    def load_geometry(self):
        geometry = {
            "x": None,
            "y": None,
            "width": DEFAULT_WIDTH,
            "height": DEFAULT_HEIGHT,
        }
        try:
            stored = json.loads(self.state_path.read_text(encoding="utf-8"))
            for key in geometry:
                if key in stored and (
                    stored[key] is None or isinstance(stored[key], int)
                ):
                    geometry[key] = stored[key]
        except (FileNotFoundError, OSError, ValueError, TypeError):
            pass
        geometry["width"] = clamp(geometry["width"], MIN_WIDTH, MAX_WIDTH)
        geometry["height"] = clamp(geometry["height"], MIN_HEIGHT, MAX_HEIGHT)
        return geometry

    def save_geometry(self):
        try:
            self.state_path.parent.mkdir(parents=True, exist_ok=True)
            temporary = self.state_path.with_suffix(".tmp")
            temporary.write_text(
                json.dumps(self.geometry, ensure_ascii=True) + "\n",
                encoding="utf-8",
            )
            temporary.replace(self.state_path)
        except OSError:
            pass
        return GLib.SOURCE_REMOVE

    def register_fcitx_service(self):
        self.bus = MessageBus().connect_sync()
        self.bus.export(VK_PATH, FcitxVirtualKeyboard(self))
        result = self.bus.request_name_sync(VK_NAME)
        if result not in (
            RequestNameReply.PRIMARY_OWNER,
            RequestNameReply.ALREADY_OWNER,
        ):
            raise RuntimeError("another Fcitx virtual keyboard is already running")

    def do_activate(self):
        if not self.held:
            self.hold()
            self.held = True
        if self.window is None:
            self.build_window()
        self.set_virtual_keyboard_mode()
        GLib.timeout_add(400, self.prime_auto_show)

    def build_window(self):
        display = Gdk.Display.get_default()
        if display is None:
            raise RuntimeError("no Wayland display is available")
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            display,
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        self.window = Gtk.ApplicationWindow(application=self)
        self.window.set_name("sheng-osk")
        self.window.add_css_class("sheng-osk")
        self.window.set_decorated(False)
        self.window.set_resizable(True)
        self.window.set_focusable(False)
        self.window.set_default_size(self.geometry["width"], self.geometry["height"])

        Gtk4LayerShell.init_for_window(self.window)
        Gtk4LayerShell.set_namespace(self.window, "sheng-osk")
        Gtk4LayerShell.set_layer(self.window, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_keyboard_mode(self.window, Gtk4LayerShell.KeyboardMode.NONE)
        Gtk4LayerShell.set_anchor(self.window, Gtk4LayerShell.Edge.TOP, True)
        Gtk4LayerShell.set_anchor(self.window, Gtk4LayerShell.Edge.LEFT, True)

        overlay = Gtk.Overlay()
        self.window.set_child(overlay)

        self.shell = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=7)
        self.shell.add_css_class("keyboard-shell")
        self.shell.set_size_request(self.geometry["width"], self.geometry["height"])
        overlay.set_child(self.shell)

        self.shell.append(self.build_header())
        self.shell.append(self.build_candidate_bar())

        self.key_area = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=7)
        self.key_area.set_vexpand(True)
        self.shell.append(self.key_area)
        self.rebuild_keys()

        self.build_resize_edges(overlay)

        self.apply_position()
        self.query_input_method_state()

    def build_header(self):
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        header.add_css_class("drag-handle")

        handle = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=9)
        handle.set_hexpand(True)
        grip = Gtk.Label(label="⠿")
        grip.add_css_class("drag-hint")
        title = Gtk.Label(label="浮动键盘")
        title.add_css_class("drag-title")
        self.drag_hint = Gtk.Label(label="拖动移动")
        self.drag_hint.add_css_class("drag-hint")
        handle.append(grip)
        handle.append(title)
        handle.append(self.drag_hint)
        drag = Gtk.GestureDrag()
        drag.connect("drag-begin", self.on_drag_begin)
        drag.connect("drag-update", self.on_drag_update)
        drag.connect("drag-end", self.on_drag_end)
        handle.add_controller(drag)
        header.append(handle)

        self.input_method_label = Gtk.Label(label="Fcitx")
        self.input_method_label.add_css_class("im-label")
        header.append(self.input_method_label)

        self.adjust_button = self.make_control_button("调整", "调整位置和大小")
        self.adjust_button.connect("clicked", self.toggle_adjust_mode)
        header.append(self.adjust_button)

        reset = self.make_control_button("重置", "重置位置和大小")
        reset.connect("clicked", self.on_reset_geometry)
        header.append(reset)

        paste = self.make_control_button("粘贴", "粘贴剪贴板")
        paste.connect("clicked", lambda _button: self.send_shortcut("v", CTRL_STATE))
        header.append(paste)

        close = self.make_control_button("收起", "收起键盘")
        close.connect(
            "clicked", lambda _button: self.request_visibility("HideVirtualKeyboard")
        )
        header.append(close)
        return header

    def build_candidate_bar(self):
        bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        bar.add_css_class("candidate-bar")

        self.previous_button = self.make_control_button("‹", "上一页候选词")
        self.previous_button.connect(
            "clicked", lambda _button: self.backend_call("PrevPage")
        )
        self.previous_button.set_sensitive(False)
        bar.append(self.previous_button)

        self.preedit_label = Gtk.Label(label="")
        self.preedit_label.add_css_class("preedit")
        self.preedit_label.set_visible(False)
        self.preedit_label.set_xalign(0)
        bar.append(self.preedit_label)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        scroll.set_hexpand(True)
        scroll.set_propagate_natural_height(True)
        self.candidate_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=3)
        scroll.set_child(self.candidate_box)
        bar.append(scroll)

        self.next_button = self.make_control_button("›", "下一页候选词")
        self.next_button.connect(
            "clicked", lambda _button: self.backend_call("NextPage")
        )
        self.next_button.set_sensitive(False)
        bar.append(self.next_button)
        return bar

    def make_control_button(self, label, tooltip):
        button = Gtk.Button(label=label)
        button.add_css_class("flat-control")
        button.set_tooltip_text(tooltip)
        return button

    def make_key(self, label, action, special=False, expand=True):
        button = Gtk.Button(label=label)
        button.add_css_class("key")
        if special:
            button.add_css_class("special-key")
        button.set_hexpand(expand)
        button.set_vexpand(True)
        button.connect("clicked", lambda _button: action())
        return button

    def make_key_row(self, items, side_padding=0):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=7)
        row.set_vexpand(True)
        if side_padding:
            spacer = Gtk.Box()
            spacer.set_size_request(side_padding, -1)
            row.append(spacer)
        for item in items:
            row.append(item)
        if side_padding:
            spacer = Gtk.Box()
            spacer.set_size_request(side_padding, -1)
            row.append(spacer)
        return row

    def rebuild_keys(self):
        while child := self.key_area.get_first_child():
            self.key_area.remove(child)

        rows = LETTER_ROWS
        if self.layer == "symbols":
            rows = SYMBOL_ROWS if self.symbol_page == 0 else MORE_SYMBOL_ROWS

        self.key_area.append(
            self.make_key_row([self.character_key(value) for value in rows[0]])
        )
        self.key_area.append(
            self.make_key_row(
                [self.character_key(value) for value in rows[1]], side_padding=34
            )
        )

        third = []
        if self.layer == "letters":
            shift_label = "⇧" if self.shift_mode != "locked" else "⇪"
            self.shift_button = self.make_key(
                shift_label, self.toggle_shift, special=True
            )
            if self.shift_mode != "off":
                self.shift_button.add_css_class("active-key")
            third.append(self.shift_button)
        else:
            third.append(
                self.make_key(
                    "#+=" if self.symbol_page == 0 else "123",
                    self.toggle_symbol_page,
                    special=True,
                )
            )
        third.extend(self.character_key(value) for value in rows[2])
        backspace = self.make_key(
            "⌫", lambda: self.send_named_key("BackSpace"), special=True
        )
        self.attach_repeat(backspace, "BackSpace")
        third.append(backspace)
        self.key_area.append(self.make_key_row(third))

        self.layer_button = self.make_key(
            "?123" if self.layer == "letters" else "ABC",
            self.toggle_layer,
            special=True,
            expand=False,
        )
        self.layer_button.set_size_request(92, -1)
        comma = self.make_key(",", lambda: self.send_character(","), expand=False)
        comma.set_size_request(68, -1)
        self.language_button = self.make_key(
            "中/英",
            self.toggle_input_method,
            special=True,
            expand=False,
        )
        self.language_button.set_size_request(82, -1)
        self.update_input_method_labels()
        space = self.make_key("空格", lambda: self.send_named_key("space"))
        period = self.make_key(".", lambda: self.send_character("."), expand=False)
        period.set_size_request(68, -1)
        enter = self.make_key(
            "↵", lambda: self.send_named_key("Return"), special=True, expand=False
        )
        enter.set_size_request(92, -1)

        bottom = self.make_key_row(
            [
                self.layer_button,
                comma,
                self.language_button,
                space,
                period,
                enter,
            ]
        )
        self.key_area.append(bottom)

    def build_resize_edges(self, overlay):
        edge_specs = [
            ("top", Gtk.Align.FILL, Gtk.Align.START, "horizontal"),
            ("bottom", Gtk.Align.FILL, Gtk.Align.END, "horizontal"),
            ("left", Gtk.Align.START, Gtk.Align.FILL, "vertical"),
            ("right", Gtk.Align.END, Gtk.Align.FILL, "vertical"),
            ("top-left", Gtk.Align.START, Gtk.Align.START, "corner"),
            ("top-right", Gtk.Align.END, Gtk.Align.START, "corner"),
            ("bottom-left", Gtk.Align.START, Gtk.Align.END, "corner"),
            ("bottom-right", Gtk.Align.END, Gtk.Align.END, "corner"),
        ]
        for direction, horizontal, vertical, style in edge_specs:
            edge = Gtk.Overlay()
            edge.add_css_class("resize-edge")
            edge.add_css_class(style)
            edge.add_css_class(direction)
            edge.set_halign(horizontal)
            edge.set_valign(vertical)
            edge.set_hexpand(horizontal == Gtk.Align.FILL)
            edge.set_vexpand(vertical == Gtk.Align.FILL)
            edge.set_visible(False)
            if style != "corner":
                indicator = Gtk.Box()
                indicator.add_css_class("resize-indicator")
                indicator.add_css_class(style)
                if style == "horizontal":
                    indicator.set_halign(Gtk.Align.CENTER)
                    indicator.set_valign(
                        Gtk.Align.START if direction == "top" else Gtk.Align.END
                    )
                else:
                    indicator.set_halign(
                        Gtk.Align.START if direction == "left" else Gtk.Align.END
                    )
                    indicator.set_valign(Gtk.Align.CENTER)
                edge.set_child(indicator)
            drag = Gtk.GestureDrag()
            drag.connect(
                "drag-begin",
                lambda gesture, x, y, direction=direction: self.on_resize_begin(
                    gesture, x, y, direction
                ),
            )
            drag.connect("drag-update", self.on_resize_update)
            drag.connect("drag-end", self.on_resize_end)
            edge.add_controller(drag)
            overlay.add_overlay(edge)
            self.resize_edges.append(edge)

    def character_key(self, value):
        label = value
        if self.layer == "letters" and self.shift_mode != "off" and value.isalpha():
            label = value.upper()
        return self.make_key(label, lambda value=value: self.send_character(value))

    def attach_repeat(self, button, key_name):
        state = {"source": 0, "long": False}

        def repeat():
            self.send_named_key(key_name)
            return GLib.SOURCE_CONTINUE

        def pressed(_gesture, _x, _y):
            state["long"] = True
            self.send_named_key(key_name)
            state["source"] = GLib.timeout_add(70, repeat)

        def ended(_gesture, _sequence=None):
            if state["source"]:
                GLib.source_remove(state["source"])
                state["source"] = 0
            GLib.idle_add(lambda: state.update(long=False) or GLib.SOURCE_REMOVE)

        long_press = Gtk.GestureLongPress()
        long_press.set_delay_factor(0.55)
        long_press.connect("pressed", pressed)
        long_press.connect("end", ended)
        long_press.connect("cancel", ended)
        button.add_controller(long_press)

    def toggle_layer(self):
        self.layer = "symbols" if self.layer == "letters" else "letters"
        self.symbol_page = 0
        self.shift_mode = "off"
        self.rebuild_keys()

    def toggle_symbol_page(self):
        self.symbol_page = 1 - self.symbol_page
        self.rebuild_keys()

    def toggle_shift(self):
        now = time.monotonic()
        if self.shift_mode == "locked":
            self.shift_mode = "off"
        elif self.shift_mode == "once" and now - self.last_shift_tap < 0.45:
            self.shift_mode = "locked"
        elif self.shift_mode == "once":
            self.shift_mode = "off"
        else:
            self.shift_mode = "once"
        self.last_shift_tap = now
        self.rebuild_keys()

    def send_character(self, value):
        state = 0
        output = value
        if self.layer == "letters" and self.shift_mode != "off" and value.isalpha():
            state = SHIFT_STATE
            output = value.upper()
        self.send_keyval(Gdk.unicode_to_keyval(ord(output)), state)
        if self.shift_mode == "once":
            self.shift_mode = "off"
            self.rebuild_keys()

    def send_named_key(self, name):
        keyval = Gdk.keyval_from_name(name)
        if keyval:
            self.send_keyval(keyval, 0)

    def send_shortcut(self, name, state):
        keyval = Gdk.keyval_from_name(name)
        if keyval:
            self.send_keyval(keyval, state)

    def toggle_input_method(self):
        if self.bus is None:
            return
        self.ignore_hide_token += 1
        token = self.ignore_hide_token
        self.bus.call(
            Message(
                destination=FCITX_NAME,
                path=CONTROLLER_PATH,
                interface=CONTROLLER_INTERFACE,
                member="Toggle",
            ),
            self.on_input_method_toggled,
        )
        GLib.timeout_add(900, self.expire_transient_hide, token)

    def on_input_method_toggled(self, _reply, _error):
        GLib.timeout_add(80, self.refresh_input_method_after_toggle)

    def refresh_input_method_after_toggle(self):
        self.query_input_method_state()
        self.request_visibility("ShowVirtualKeyboard")
        return GLib.SOURCE_REMOVE

    def query_input_method_state(self):
        if self.bus is None:
            return GLib.SOURCE_REMOVE
        self.bus.call(
            Message(
                destination=FCITX_NAME,
                path=CONTROLLER_PATH,
                interface=CONTROLLER_INTERFACE,
                member="State",
            ),
            self.on_input_method_state,
        )
        return GLib.SOURCE_REMOVE

    def on_input_method_state(self, reply, error):
        if (
            error is None
            and reply is not None
            and reply.message_type != MessageType.ERROR
            and reply.body
        ):
            GLib.idle_add(self.set_input_method_active, reply.body[0] == 2)

    def set_input_method_active(self, active):
        self.input_method_active = active
        self.update_input_method_labels()
        if not active:
            self.set_preedit("")
            self.set_candidates([], False, False, -1, -1)
        return GLib.SOURCE_REMOVE

    def update_input_method_labels(self):
        if self.input_method_label is not None:
            label = "中文"
            if self.input_method_active and self.current_input_method:
                label = f"中文 · {self.current_input_method}"
            elif not self.input_method_active:
                label = "English"
            self.input_method_label.set_label(label)
        if self.language_button is not None:
            if self.input_method_active:
                self.language_button.set_label("中")
                self.language_button.set_tooltip_text("切换到 English")
                self.language_button.add_css_class("active-key")
            else:
                self.language_button.set_label("EN")
                self.language_button.set_tooltip_text("切换到中文")
                self.language_button.remove_css_class("active-key")

    def send_keyval(self, keyval, state):
        timestamp = int(time.monotonic() * 1000) & 0xFFFFFFFF
        self.backend_call(
            "ProcessKeyEvent", "uuubu", [keyval, 0, state, False, timestamp]
        )
        self.backend_call(
            "ProcessKeyEvent", "uuubu", [keyval, 0, state, True, timestamp]
        )

    def backend_call(self, member, signature="", body=None):
        if self.bus is None:
            return
        self.bus.send(
            Message(
                destination=BACKEND_NAME,
                path=BACKEND_PATH,
                interface=BACKEND_INTERFACE,
                member=member,
                signature=signature,
                body=body or [],
                flags=MessageFlag.NO_REPLY_EXPECTED,
            )
        )

    def request_visibility(self, member):
        if self.bus is None:
            return
        self.bus.send(
            Message(
                destination=FCITX_NAME,
                path=FCITX_PATH,
                interface=FCITX_INTERFACE,
                member=member,
                flags=MessageFlag.NO_REPLY_EXPECTED,
            )
        )

    def prime_auto_show(self):
        if self.primed or self.bus is None:
            return GLib.SOURCE_REMOVE
        self.prime_attempts += 1
        self.priming = True
        self.bus.call(
            Message(
                destination=FCITX_NAME,
                path=FCITX_PATH,
                interface=FCITX_INTERFACE,
                member="ShowVirtualKeyboard",
            ),
            self.on_prime_show,
        )
        return GLib.SOURCE_REMOVE

    def on_prime_show(self, reply, error):
        if (
            error is not None
            or reply is None
            or reply.message_type == MessageType.ERROR
        ):
            self.priming = False
            if self.prime_attempts < 20:
                GLib.timeout_add(500, self.prime_auto_show)
            return
        self.primed = True
        self.set_virtual_keyboard_mode()
        GLib.timeout_add(80, self.finish_prime_auto_show)

    def finish_prime_auto_show(self):
        self.request_visibility("HideVirtualKeyboard")
        GLib.timeout_add(120, self.finish_priming)
        return GLib.SOURCE_REMOVE

    def finish_priming(self):
        self.priming = False
        return GLib.SOURCE_REMOVE

    def set_virtual_keyboard_mode(self):
        self.backend_call("SetVirtualKeyboardFunctionMode", "u", [1])
        return GLib.SOURCE_REMOVE

    def show_keyboard(self, _reason=""):
        if self.window is None:
            self.activate()
            return GLib.SOURCE_REMOVE
        self.apply_position()
        self.window.present()
        self.backend_call("ProcessVisibilityEvent", "b", [True])
        return GLib.SOURCE_REMOVE

    def hide_keyboard(self, _reason=""):
        self.set_adjust_mode(False)
        if self.window is not None:
            self.window.set_visible(False)
        self.backend_call("ProcessVisibilityEvent", "b", [False])
        return GLib.SOURCE_REMOVE

    def set_preedit(self, text):
        self.preedit = text
        self.refresh_preedit()
        return GLib.SOURCE_REMOVE

    def set_preedit_caret(self, caret):
        self.preedit_caret = caret
        self.refresh_preedit()
        return GLib.SOURCE_REMOVE

    def refresh_preedit(self):
        if self.preedit_label is None:
            return
        text = self.preedit
        if text and 0 <= self.preedit_caret <= len(text):
            text = text[: self.preedit_caret] + "│" + text[self.preedit_caret :]
        self.preedit_label.set_label(text)
        self.preedit_label.set_visible(bool(text))

    def set_candidates(self, candidates, has_previous, has_next, page, cursor):
        self.candidates = list(candidates)
        self.has_previous = has_previous
        self.has_next = has_next
        self.page = page
        self.candidate_cursor = cursor
        if self.candidate_box is None:
            return GLib.SOURCE_REMOVE

        while child := self.candidate_box.get_first_child():
            self.candidate_box.remove(child)
        for index, text in enumerate(self.candidates):
            if not text:
                continue
            button = Gtk.Button(label=text)
            button.add_css_class("candidate")
            if index == self.candidate_cursor:
                button.add_css_class("current")
            button.connect(
                "clicked",
                lambda _button, index=index: self.select_candidate(index),
            )
            self.candidate_box.append(button)
        self.previous_button.set_sensitive(has_previous)
        self.next_button.set_sensitive(has_next)
        return GLib.SOURCE_REMOVE

    def select_candidate(self, index):
        self.ignore_hide_token += 1
        token = self.ignore_hide_token
        self.backend_call("SelectCandidate", "i", [index])
        GLib.timeout_add(900, self.expire_transient_hide, token)

    def consume_transient_hide(self):
        if self.ignore_hide_token == 0:
            return False
        self.ignore_hide_token = 0
        return True

    def expire_transient_hide(self, token):
        if self.ignore_hide_token == token:
            self.ignore_hide_token = 0
        return GLib.SOURCE_REMOVE

    def set_input_method(self, unique_name):
        self.current_input_method = unique_name.split(":")[0] if unique_name else ""
        self.input_method_active = bool(
            self.current_input_method
            and not self.current_input_method.startswith("keyboard-")
        )
        self.update_input_method_labels()
        return GLib.SOURCE_REMOVE

    def output_size(self):
        display = Gdk.Display.get_default()
        if display is None:
            return 1524, 1016
        monitors = display.get_monitors()
        if monitors.get_n_items() == 0:
            return 1524, 1016
        geometry = monitors.get_item(0).get_geometry()
        return geometry.width, geometry.height

    def clamp_geometry(self):
        screen_width, screen_height = self.output_size()
        self.geometry["width"] = clamp(
            self.geometry["width"], MIN_WIDTH, min(MAX_WIDTH, screen_width - 20)
        )
        self.geometry["height"] = clamp(
            self.geometry["height"], MIN_HEIGHT, min(MAX_HEIGHT, screen_height - 20)
        )
        max_x = max(0, screen_width - self.geometry["width"] - EDGE_MARGIN)
        max_y = max(0, screen_height - self.geometry["height"] - EDGE_MARGIN)
        if self.geometry["x"] is None:
            self.geometry["x"] = max(EDGE_MARGIN, max_x // 2)
        if self.geometry["y"] is None:
            self.geometry["y"] = max(EDGE_MARGIN, max_y)
        self.geometry["x"] = clamp(self.geometry["x"], EDGE_MARGIN, max_x)
        self.geometry["y"] = clamp(self.geometry["y"], EDGE_MARGIN, max_y)

    def apply_position(self):
        if self.window is None:
            return
        self.clamp_geometry()
        Gtk4LayerShell.set_margin(
            self.window, Gtk4LayerShell.Edge.LEFT, self.geometry["x"]
        )
        Gtk4LayerShell.set_margin(
            self.window, Gtk4LayerShell.Edge.TOP, self.geometry["y"]
        )
        self.window.set_default_size(self.geometry["width"], self.geometry["height"])
        self.shell.set_size_request(self.geometry["width"], self.geometry["height"])

    def on_drag_begin(self, _gesture, _x, _y):
        self.drag_origin = (self.geometry["x"], self.geometry["y"])

    def on_drag_update(self, _gesture, offset_x, offset_y):
        self.geometry["x"] = int(self.drag_origin[0] + offset_x)
        self.geometry["y"] = int(self.drag_origin[1] + offset_y)
        self.apply_position()

    def on_drag_end(self, _gesture, _offset_x, _offset_y):
        self.save_geometry()

    def toggle_adjust_mode(self, _button):
        self.set_adjust_mode(not self.adjusting)

    def set_adjust_mode(self, active):
        self.adjusting = active
        for edge in self.resize_edges:
            edge.set_visible(active)
        if self.adjust_button is not None:
            self.adjust_button.set_label("完成" if active else "调整")
            if active:
                self.adjust_button.add_css_class("active-key")
            else:
                self.adjust_button.remove_css_class("active-key")
        if self.drag_hint is not None:
            self.drag_hint.set_label("拖动边缘或四角缩放" if active else "拖动移动")

    def on_resize_begin(self, _gesture, _x, _y, direction):
        self.resize_direction = direction
        self.resize_origin = dict(self.geometry)

    def on_resize_update(self, _gesture, offset_x, offset_y):
        if self.resize_origin is None:
            return
        origin = self.resize_origin
        screen_width, screen_height = self.output_size()
        max_width = min(MAX_WIDTH, screen_width - EDGE_MARGIN * 2)
        max_height = min(MAX_HEIGHT, screen_height - EDGE_MARGIN * 2)
        left = origin["x"]
        top = origin["y"]
        right = left + origin["width"]
        bottom = top + origin["height"]

        if "left" in self.resize_direction:
            left = clamp(
                int(origin["x"] + offset_x),
                max(EDGE_MARGIN, right - max_width),
                right - MIN_WIDTH,
            )
        elif "right" in self.resize_direction:
            right = clamp(
                int(origin["x"] + origin["width"] + offset_x),
                origin["x"] + MIN_WIDTH,
                min(screen_width - EDGE_MARGIN, origin["x"] + max_width),
            )

        if "top" in self.resize_direction:
            top = clamp(
                int(origin["y"] + offset_y),
                max(EDGE_MARGIN, bottom - max_height),
                bottom - MIN_HEIGHT,
            )
        elif "bottom" in self.resize_direction:
            bottom = clamp(
                int(origin["y"] + origin["height"] + offset_y),
                origin["y"] + MIN_HEIGHT,
                min(screen_height - EDGE_MARGIN, origin["y"] + max_height),
            )

        self.geometry["x"] = left
        self.geometry["y"] = top
        self.geometry["width"] = right - left
        self.geometry["height"] = bottom - top
        self.apply_position()

    def on_resize_end(self, _gesture, _offset_x, _offset_y):
        self.resize_origin = None
        self.resize_direction = ""
        self.save_geometry()

    def on_reset_geometry(self, _button):
        self.geometry = {
            "x": None,
            "y": None,
            "width": DEFAULT_WIDTH,
            "height": DEFAULT_HEIGHT,
        }
        self.apply_position()
        self.save_geometry()


def main():
    application = ShengOsk()
    application.register_fcitx_service()
    raise SystemExit(application.run())


if __name__ == "__main__":
    main()
