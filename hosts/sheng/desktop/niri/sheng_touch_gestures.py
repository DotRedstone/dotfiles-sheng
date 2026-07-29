#!/usr/bin/env python3

import argparse
import json
import os
import select
import socket
import subprocess
import time
from dataclasses import dataclass

from evdev import InputDevice, ecodes


EDGE_SIZE = 110
PREVIEW_DISTANCE = 24
COMMIT_DISTANCE = 170
MAX_DURATION = 2.5
RECENTS_HOLD = 0.48
DIRECTION_BIAS = 1.12


@dataclass
class Contact:
    tracking_id: int = -1
    x: int | None = None
    y: int | None = None


@dataclass
class Gesture:
    tracking_id: int
    edge: str
    start_x: float
    start_y: float
    x: float
    y: float
    started: float
    event: str | None = None
    previewed: bool = False
    ignored: bool = False


class GestureRecognizer:
    def __init__(self, width, height, transform, feedback, action):
        self.native_width = width
        self.native_height = height
        self.transform = transform
        self.feedback = feedback
        self.action = action
        self.gesture = None

    @property
    def visual_size(self):
        if self.transform in ("90", "270"):
            return self.native_height, self.native_width
        return self.native_width, self.native_height

    def transform_point(self, x, y):
        width = self.native_width
        height = self.native_height
        if self.transform == "90":
            return height - y, x
        if self.transform == "180":
            return width - x, height - y
        if self.transform == "270":
            return y, width - x
        return x, y

    def edge_at(self, x, y):
        width, height = self.visual_size
        if y >= height - EDGE_SIZE:
            return "bottom"
        if y <= EDGE_SIZE:
            return "top"
        if x <= EDGE_SIZE:
            return "left"
        if x >= width - EDGE_SIZE:
            return "right"
        return None

    def begin(self, tracking_id, raw_x, raw_y, now=None):
        x, y = self.transform_point(raw_x, raw_y)
        edge = self.edge_at(x, y)
        if not edge:
            return
        now = now if now is not None else time.monotonic()
        self.gesture = Gesture(
            tracking_id=tracking_id,
            edge=edge,
            start_x=x,
            start_y=y,
            x=x,
            y=y,
            started=now,
        )

    def movement(self, gesture, x, y, now):
        dx = x - gesture.start_x
        dy = y - gesture.start_y
        edge = gesture.edge

        if edge == "left":
            return "back-left", dx, abs(dy), gesture.start_y
        if edge == "right":
            return "back-right", -dx, abs(dy), gesture.start_y
        if edge == "top":
            return "control-center", dy, abs(dx), gesture.start_x

        upward = -dy
        horizontal = dx
        if abs(horizontal) > max(PREVIEW_DISTANCE, upward * DIRECTION_BIAS):
            event = "column-right" if horizontal < 0 else "column-left"
            return event, abs(horizontal), max(0, upward), gesture.start_x

        elapsed = now - gesture.started
        event = "recents" if elapsed >= RECENTS_HOLD and upward >= 120 else "home"
        return event, upward, abs(horizontal), gesture.start_x

    def update(self, raw_x, raw_y, now=None):
        gesture = self.gesture
        if not gesture or gesture.ignored:
            return

        now = now if now is not None else time.monotonic()
        x, y = self.transform_point(raw_x, raw_y)
        gesture.x = x
        gesture.y = y

        event, primary, cross, position = self.movement(gesture, x, y, now)
        if primary < 0 or cross > max(90, primary * 1.35):
            if gesture.previewed:
                self.feedback("cancel", gesture.event, 0, position, gesture.edge)
            gesture.ignored = True
            return

        if primary < PREVIEW_DISTANCE:
            return

        progress = min(primary / COMMIT_DISTANCE, 1.0)
        phase = "begin" if not gesture.previewed else "update"
        gesture.previewed = True
        gesture.event = event
        self.feedback(phase, event, progress, position, gesture.edge)

    def finish(self, now=None):
        gesture = self.gesture
        self.gesture = None
        if not gesture or gesture.ignored:
            return None

        now = now if now is not None else time.monotonic()
        event, primary, cross, position = self.movement(
            gesture, gesture.x, gesture.y, now
        )
        duration = now - gesture.started
        committed = (
            primary >= COMMIT_DISTANCE
            and cross <= max(90, primary * 1.35)
            and duration <= MAX_DURATION
        )

        if committed:
            self.feedback("commit", event, 1, position, gesture.edge)
            self.action(event)
            return event

        if gesture.previewed:
            self.feedback(
                "cancel",
                gesture.event or event,
                min(max(primary, 0) / COMMIT_DISTANCE, 1),
                position,
                gesture.edge,
            )
        return None

    def cancel(self):
        if self.gesture and self.gesture.previewed:
            event = self.gesture.event or "back"
            position = (
                self.gesture.start_y
                if self.gesture.edge in ("left", "right")
                else self.gesture.start_x
            )
            self.feedback("cancel", event, 0, position, self.gesture.edge)
        self.gesture = None

    def tick(self, now=None):
        gesture = self.gesture
        if not gesture or gesture.ignored:
            return
        now = now if now is not None else time.monotonic()
        if now - gesture.started > MAX_DURATION:
            if gesture.previewed:
                event = gesture.event or "back"
                position = (
                    gesture.start_y
                    if gesture.edge in ("left", "right")
                    else gesture.start_x
                )
                self.feedback("cancel", event, 0, position, gesture.edge)
            gesture.ignored = True
            return
        if gesture.edge == "bottom" and gesture.previewed:
            event, primary, _cross, position = self.movement(
                gesture, gesture.x, gesture.y, now
            )
            if event != gesture.event:
                gesture.event = event
                self.feedback(
                    "update",
                    event,
                    min(max(primary, 0) / COMMIT_DISTANCE, 1),
                    position,
                    gesture.edge,
                )


class GestureDaemon:
    def __init__(self, device_path, action_path, niri_path):
        self.device = InputDevice(device_path)
        self.action_path = action_path
        self.niri_path = niri_path
        self.runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        self.feedback_path = os.path.join(
            self.runtime_dir, "sheng-niri-gesture-feedback.sock"
        )
        self.feedback_socket = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.slots = {}
        self.slot = 0
        self.blocked_until_clear = False

        x_info = self.device.absinfo(ecodes.ABS_MT_POSITION_X)
        y_info = self.device.absinfo(ecodes.ABS_MT_POSITION_Y)
        self.x_min = x_info.min
        self.y_min = y_info.min
        self.width = x_info.max - x_info.min + 1
        self.height = y_info.max - y_info.min + 1
        self.recognizer = GestureRecognizer(
            self.width,
            self.height,
            self.get_transform(),
            self.send_feedback,
            self.run_action,
        )

    def get_transform(self):
        try:
            result = subprocess.run(
                [self.niri_path, "msg", "--json", "outputs"],
                check=True,
                capture_output=True,
                text=True,
                timeout=1,
            )
            outputs = json.loads(result.stdout)
            output = outputs.get("DSI-1", {})
            logical = output.get("logical") or {}
            return str(logical.get("transform", "normal")).lower()
        except (OSError, subprocess.SubprocessError, ValueError):
            return "normal"

    def normalized(self, contact):
        return contact.x - self.x_min, contact.y - self.y_min

    def send_feedback(self, phase, event, progress, position, edge):
        width, height = self.recognizer.visual_size
        span = height if edge in ("left", "right") else width
        payload = json.dumps(
            {
                "phase": phase,
                "event": event,
                "progress": round(progress, 4),
                "position": round(min(max(position / max(span, 1), 0), 1), 4),
            },
            separators=(",", ":"),
        ).encode("ascii")
        try:
            self.feedback_socket.sendto(payload, self.feedback_path)
        except (FileNotFoundError, ConnectionRefusedError, OSError):
            pass

    def run_action(self, event):
        environment = os.environ.copy()
        environment["SHENG_GESTURE_FEEDBACK"] = "0"
        subprocess.Popen(
            [self.action_path, event],
            env=environment,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )

    def active_contacts(self):
        return [
            contact
            for contact in self.slots.values()
            if contact.tracking_id >= 0
            and contact.x is not None
            and contact.y is not None
        ]

    def process_frame(self):
        active = self.active_contacts()
        gesture = self.recognizer.gesture

        if self.blocked_until_clear:
            if not active:
                self.blocked_until_clear = False
            return

        if gesture:
            tracked = next(
                (item for item in active if item.tracking_id == gesture.tracking_id),
                None,
            )
            if len(active) > 1:
                self.recognizer.cancel()
                self.blocked_until_clear = True
            elif tracked:
                self.recognizer.update(*self.normalized(tracked))
            else:
                self.recognizer.finish()
        elif len(active) == 1:
            contact = active[0]
            x, y = self.normalized(contact)
            self.recognizer.begin(contact.tracking_id, x, y)

        self.slots = {
            slot: contact
            for slot, contact in self.slots.items()
            if contact.tracking_id >= 0
        }

    def run(self):
        while True:
            readable, _, _ = select.select([self.device.fd], [], [], 0.03)
            if not readable:
                self.recognizer.tick()
                continue
            for event in self.device.read():
                if event.type == ecodes.EV_ABS:
                    if event.code == ecodes.ABS_MT_SLOT:
                        self.slot = event.value
                    else:
                        contact = self.slots.setdefault(self.slot, Contact())
                        if event.code == ecodes.ABS_MT_TRACKING_ID:
                            contact.tracking_id = event.value
                        elif event.code == ecodes.ABS_MT_POSITION_X:
                            contact.x = event.value
                        elif event.code == ecodes.ABS_MT_POSITION_Y:
                            contact.y = event.value
                elif event.type == ecodes.EV_SYN and event.code == ecodes.SYN_REPORT:
                    self.process_frame()


def self_test():
    feedback = []
    actions = []
    recognizer = GestureRecognizer(
        3048,
        2032,
        "normal",
        lambda *message: feedback.append(message),
        actions.append,
    )

    cases = [
        ("back-left", (5, 800), (240, 810), 0.2),
        ("back-right", (3043, 800), (2800, 790), 0.2),
        ("home", (1500, 2028), (1500, 1800), 0.25),
        ("recents", (1500, 2028), (1500, 1780), 0.7),
        ("column-right", (1500, 2028), (1260, 2010), 0.25),
        ("column-left", (1500, 2028), (1740, 2010), 0.25),
        ("control-center", (1500, 3), (1500, 230), 0.25),
    ]
    for expected, start, end, duration in cases:
        feedback.clear()
        actions.clear()
        recognizer.begin(1, *start, now=10)
        recognizer.update(*end, now=10 + duration)
        actual = recognizer.finish(now=10 + duration)
        assert actual == expected, (expected, actual)
        assert actions == [expected], (expected, actions)
        assert feedback[-1][0] == "commit", (expected, feedback)

    recognizer.begin(1, 5, 800, now=20)
    recognizer.update(70, 805, now=20.1)
    assert recognizer.finish(now=20.2) is None
    assert feedback[-1][0] == "cancel"

    feedback.clear()
    actions.clear()
    recognizer.begin(1, 1500, 2028, now=25)
    recognizer.update(1500, 1820, now=25.2)
    assert feedback[-1][1] == "home"
    recognizer.tick(now=25.6)
    assert feedback[-1][1] == "recents"
    assert recognizer.finish(now=25.7) == "recents"

    feedback.clear()
    actions.clear()
    recognizer.begin(1, 5, 800, now=27)
    recognizer.update(105, 1000, now=27.2)
    assert recognizer.finish(now=27.3) is None
    assert actions == []

    feedback.clear()
    actions.clear()
    recognizer.begin(1, 5, 800, now=28)
    recognizer.update(90, 800, now=28.2)
    recognizer.tick(now=31)
    assert feedback[-1][0] == "cancel"
    assert recognizer.finish(now=31.1) is None

    rotation_cases = [
        ("90", (800, 2027), (800, 1800)),
        ("180", (3043, 800), (2800, 800)),
        ("270", (800, 5), (800, 240)),
    ]
    for transform, start, end in rotation_cases:
        feedback.clear()
        actions.clear()
        recognizer.transform = transform
        recognizer.begin(1, *start, now=30)
        recognizer.update(*end, now=30.2)
        assert recognizer.finish(now=30.2) == "back-left", transform

    print("gesture recognizer: 14 cases passed")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", default="/dev/input/touchscreen")
    parser.add_argument("--action", required=False)
    parser.add_argument("--niri", default="niri")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return
    if not args.action:
        parser.error("--action is required")
    GestureDaemon(args.device, args.action, args.niri).run()


if __name__ == "__main__":
    main()
