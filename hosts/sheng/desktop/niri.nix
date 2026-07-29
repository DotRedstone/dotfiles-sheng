# ---
# Module: Niri Desktop
# Description: Touch-friendly Niri session for Xiaomi Pad 6S Pro
# Scope: System
# ---

{
  config,
  lib,
  pkgs,
  ...
}:

let
  oskPython = pkgs.python3.withPackages (
    pythonPackages: with pythonPackages; [
      dbus-next
      pygobject3
    ]
  );

  touchPython = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.evdev
  ]);

  oskTypelibPath = lib.makeSearchPath "lib/girepository-1.0" (
    map lib.getLib [
      pkgs.at-spi2-core
      pkgs.gdk-pixbuf
      pkgs.glib
      pkgs.gobject-introspection
      pkgs.graphene
      pkgs.gtk4
      pkgs.gtk4-layer-shell
      pkgs.harfbuzz
      pkgs.pango
    ]
  );

  niriOsk = pkgs.stdenvNoCC.mkDerivation {
    pname = "sheng-niri-osk";
    version = "1.0.0";
    src = ./niri/sheng_osk.py;
    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.wrapGAppsHook4
    ];
    buildInputs = [
      pkgs.gtk4
      pkgs.gtk4-layer-shell
    ];
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall
      install -Dm644 "$src" "$out/libexec/sheng_osk.py"
      mkdir -p "$out/bin"
      runHook postInstall
    '';

    preFixup = ''
      makeWrapper ${oskPython}/bin/python3 "$out/bin/sheng-niri-osk" \
        --add-flags "$out/libexec/sheng_osk.py" \
        --set LD_PRELOAD "${lib.getLib pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so" \
        --prefix GI_TYPELIB_PATH : "${oskTypelibPath}" \
        "''${gappsWrapperArgs[@]}"
    '';
  };

  niriGestureFeedback = pkgs.stdenvNoCC.mkDerivation {
    pname = "sheng-niri-gesture-feedback";
    version = "1.0.0";
    src = ./niri/sheng_gesture_feedback.py;
    dontUnpack = true;

    nativeBuildInputs = [
      pkgs.makeWrapper
      pkgs.wrapGAppsHook4
    ];
    buildInputs = [
      pkgs.gtk4
      pkgs.gtk4-layer-shell
    ];
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall
      install -Dm644 "$src" "$out/libexec/sheng_gesture_feedback.py"
      mkdir -p "$out/bin"
      runHook postInstall
    '';

    preFixup = ''
      makeWrapper ${oskPython}/bin/python3 "$out/bin/sheng-niri-gesture-feedback" \
        --add-flags "$out/libexec/sheng_gesture_feedback.py" \
        --set LD_PRELOAD "${lib.getLib pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so" \
        --prefix GI_TYPELIB_PATH : "${oskTypelibPath}" \
        "''${gappsWrapperArgs[@]}"
    '';
  };

  niriTouchDaemon = pkgs.stdenvNoCC.mkDerivation {
    pname = "sheng-niri-touch-gestures";
    version = "2.0.0";
    src = ./niri/sheng_touch_gestures.py;
    dontUnpack = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      install -Dm644 "$src" "$out/libexec/sheng_touch_gestures.py"
      makeWrapper ${touchPython}/bin/python3 "$out/bin/sheng-niri-touch-gestures" \
        --add-flags "$out/libexec/sheng_touch_gestures.py"
      runHook postInstall
    '';
  };

  regreetSession = pkgs.writeShellScript "sheng-regreet-session" ''
    set -eu

    ${pkgs.wvkbd}/bin/wvkbd-mobintl -L 300 &
    osk_pid=$!

    cleanup() {
      kill "$osk_pid" 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM

    ${lib.getExe config.programs.regreet.package}
    ${pkgs.niri}/bin/niri msg action quit --skip-confirmation
  '';

  regreetNiriConfig = pkgs.writeText "sheng-regreet-niri.kdl" ''
    input {
        keyboard {
            xkb {
                layout "us"
            }
            numlock
        }

        touchpad {
            tap
            natural-scroll
            dwt
        }
    }

    output "DSI-1" {
        mode "3048x2032"
        scale 2
        transform "normal"
        focus-at-startup
    }

    layout {
        gaps 0
        background-color "#101419"

        focus-ring {
            off
        }

        border {
            off
        }
    }

    hotkey-overlay {
        skip-at-startup
    }

    cursor {
        hide-when-typing
        hide-after-inactive-ms 4000
    }

    environment {
        GTK_USE_PORTAL "0"
        GDK_DEBUG "no-portals"
    }

    animations {
        off
    }

    prefer-no-csd
    spawn-at-startup "${regreetSession}"
  '';

  niriDisplay = pkgs.writeShellScriptBin "sheng-niri-display" ''
    set -eu

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    state_file="$runtime_dir/sheng-niri-display-state"
    socket="''${NIRI_SOCKET:-}"

    if [ -z "$socket" ]; then
      socket="$(
        ${pkgs.findutils}/bin/find "$runtime_dir" -maxdepth 1 -type s \
          -name 'niri.*.sock' -print 2>/dev/null |
          ${pkgs.coreutils}/bin/head -n 1
      )"
    fi

    if [ -z "$socket" ]; then
      echo "No active Niri IPC socket found." >&2
      exit 1
    fi

    current="$(${pkgs.coreutils}/bin/cat "$state_file" 2>/dev/null || echo on)"
    requested="''${1:-toggle}"

    case "$requested" in
      on|off)
        target="$requested"
        ;;
      toggle)
        if [ "$current" = "on" ]; then
          target="off"
        else
          target="on"
        fi
        ;;
      *)
        echo "Usage: sheng-niri-display [on|off|toggle]" >&2
        exit 2
        ;;
    esac

    NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg output DSI-1 "$target"
    printf '%s\n' "$target" > "$state_file"
  '';

  niriOskToggle = pkgs.writeShellScriptBin "sheng-niri-osk-toggle" ''
    set -u

    if ${pkgs.systemd}/bin/busctl --user call \
      org.fcitx.Fcitx5 \
      /virtualkeyboard \
      org.fcitx.Fcitx.VirtualKeyboard1 \
      ToggleVirtualKeyboard >/dev/null 2>&1; then
      exit 0
    fi

    exec ${lib.getExe config.programs.noctalia.package} \
      msg panel-toggle dotredstone/touch-controls:keyboard
  '';

  niriOskInput = pkgs.writeShellScript "sheng-niri-osk-input" ''
    set -eu

    export DOTOOL_PIPE="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/sheng-dotool-pipe"
    export DOTOOL_KEYBOARD_NAME="Sheng Touch Keyboard"
    export DOTOOL_XKB_LAYOUT="us"
    exec ${pkgs.dotool}/bin/dotoold
  '';

  niriKey = pkgs.writeShellScriptBin "sheng-niri-key" ''
    set -eu

    if [ "$#" -ne 1 ]; then
      exit 2
    fi

    token="$1"
    case "$token" in
      [a-z]|[0-9])
        action="key $token"
        ;;
      upper-[a-z])
        action="key shift+''${token#upper-}"
        ;;
      backspace|enter|tab|space|left|right|up|down|delete|escape)
        action="key $token"
        ;;
      app-back)
        action="key alt+left"
        ;;
      language)
        action="key ctrl+space"
        ;;
      paste)
        action="key ctrl+v"
        ;;
      comma|dot|minus|equal|left-bracket|right-bracket|apostrophe|semicolon|slash|backslash|grave)
        case "$token" in
          left-bracket) key="leftbrace" ;;
          right-bracket) key="rightbrace" ;;
          *) key="$token" ;;
        esac
        action="key $key"
        ;;
      exclam) action="key shift+1" ;;
      at) action="key shift+2" ;;
      hash) action="key shift+3" ;;
      dollar) action="key shift+4" ;;
      percent) action="key shift+5" ;;
      caret) action="key shift+6" ;;
      ampersand) action="key shift+7" ;;
      asterisk) action="key shift+8" ;;
      left-paren) action="key shift+9" ;;
      right-paren) action="key shift+0" ;;
      underscore) action="key shift+minus" ;;
      plus) action="key shift+equal" ;;
      left-brace) action="key shift+leftbrace" ;;
      right-brace) action="key shift+rightbrace" ;;
      pipe) action="key shift+backslash" ;;
      colon) action="key shift+semicolon" ;;
      double-quote) action="key shift+apostrophe" ;;
      tilde) action="key shift+grave" ;;
      less) action="key shift+comma" ;;
      greater) action="key shift+dot" ;;
      question) action="key shift+slash" ;;
      *)
        exit 2
        ;;
    esac

    export DOTOOL_PIPE="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}/sheng-dotool-pipe"
    if [ ! -p "$DOTOOL_PIPE" ]; then
      ${pkgs.systemd}/bin/systemctl --user start sheng-niri-osk-input.service
    fi

    attempt=0
    while [ "$attempt" -lt 3 ]; do
      if printf '%s\n' "$action" | ${pkgs.dotool}/bin/dotoolc; then
        exit 0
      fi
      attempt=$((attempt + 1))
      ${pkgs.coreutils}/bin/sleep 0.04
    done
    exit 1
  '';

  niriLock = pkgs.writeShellScriptBin "sheng-niri-lock" ''
    exec ${pkgs.swaylock}/bin/swaylock \
      --config /etc/xdg/swaylock/config \
      --daemonize
  '';

  niriTouchAction = pkgs.writeShellScriptBin "sheng-niri-touch-action" ''
    set -eu

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    feedback_socket="$runtime_dir/sheng-niri-gesture-feedback.sock"

    show_feedback() {
      if [ -S "$feedback_socket" ]; then
        printf '%s\n' "$1" |
          ${pkgs.socat}/bin/socat -u - "UNIX-SENDTO:$feedback_socket" >/dev/null 2>&1 || true
      fi
    }

    case "''${1:-}" in
      launcher)
        exec ${lib.getExe config.programs.noctalia.package} msg panel-toggle launcher
        ;;
      control-center)
        show_feedback control-center
        exec ${lib.getExe config.programs.noctalia.package} msg panel-toggle control-center
        ;;
      back|back-left|back-right|home|recents|column-left|column-right|workspace-up|workspace-down|overview|close|fullscreen|maximize)
        ;;
      *)
        exit 2
        ;;
    esac

    socket="''${NIRI_SOCKET:-}"
    if [ -z "$socket" ]; then
      socket="$(
        ${pkgs.findutils}/bin/find "$runtime_dir" -maxdepth 1 -type s \
          -name 'niri.*.sock' -print 2>/dev/null |
          ${pkgs.coreutils}/bin/head -n 1
      )"
    fi

    if [ -z "$socket" ]; then
      exit 0
    fi

    if [ "''${SHENG_GESTURE_FEEDBACK:-1}" != 0 ]; then
      show_feedback "$1"
    fi

    case "$1" in
      back|back-left|back-right)
        overview_state="$(
          NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg --json overview-state 2>/dev/null ||
            printf '{"is_open":false}'
        )"
        if printf '%s' "$overview_state" |
          ${pkgs.jq}/bin/jq -e '.is_open == true' >/dev/null 2>&1; then
          action="close-overview"
        else
          focused_window="$(
            NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg --json focused-window 2>/dev/null ||
              printf 'null'
          )"
          focused_output="$(
            NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg --json focused-output 2>/dev/null ||
              printf 'null'
          )"
          if ${pkgs.jq}/bin/jq -n -e \
            --argjson window "$focused_window" \
            --argjson output "$focused_output" \
            '
              $window.is_fullscreen == true or
              (
                $window.layout.window_size[0] == $output.logical.width and
                $window.layout.window_size[1] == $output.logical.height
              )
            ' >/dev/null 2>&1; then
            action="fullscreen-window"
          else
            exec ${niriKey}/bin/sheng-niri-key app-back
          fi
        fi
        ;;
      close)
        action="close-window"
        ;;
      home)
        action="focus-workspace"
        action_arg="1"
        ;;
      recents)
        action="open-overview"
        ;;
      overview)
        action="toggle-overview"
        ;;
      column-left)
        action="focus-column-left-or-last"
        ;;
      column-right)
        action="focus-column-right-or-first"
        ;;
      workspace-up)
        action="focus-workspace-up"
        ;;
      workspace-down)
        action="focus-workspace-down"
        ;;
      fullscreen)
        action="fullscreen-window"
        ;;
      maximize)
        action="maximize-column"
        ;;
    esac

    if [ -n "''${action_arg:-}" ]; then
      NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg action "$action" "$action_arg"
    else
      NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg action "$action"
    fi
  '';

  niriTouchGestures = pkgs.writeShellScriptBin "sheng-niri-touch-gestures" ''
    exec ${niriTouchDaemon}/bin/sheng-niri-touch-gestures \
      --device /dev/input/touchscreen \
      --action ${niriTouchAction}/bin/sheng-niri-touch-action \
      --niri ${pkgs.niri}/bin/niri
  '';

  displayControls = pkgs.writeScript "sheng-niri-display-controls" ''
    #!${pkgs.python3.withPackages (p: [ p.evdev ])}/bin/python3
    import select
    import subprocess
    import time

    import evdev
    from evdev import ecodes

    DISPLAY_COMMAND = "${niriDisplay}/bin/sheng-niri-display"


    def find_device(name, event_type, event_code):
        for path in evdev.list_devices():
            try:
                device = evdev.InputDevice(path)
                capabilities = device.capabilities()
                if device.name == name and event_code in capabilities.get(event_type, []):
                    return device
                device.close()
            except OSError:
                continue
        return None


    def set_display(action):
        subprocess.run([DISPLAY_COMMAND, action], check=False)


    while True:
        power = find_device("pmic_pwrkey", ecodes.EV_KEY, ecodes.KEY_POWER)
        lid = find_device("gpio-keys", ecodes.EV_SW, ecodes.SW_LID)
        if power is not None and lid is not None:
            break
        if power is not None:
            power.close()
        if lid is not None:
            lid.close()
        time.sleep(1)

    power.grab()
    set_display("on")

    try:
        while True:
            ready, _, _ = select.select([power.fd, lid.fd], [], [], 5)
            for fd in ready:
                device = power if fd == power.fd else lid
                for event in device.read():
                    if (
                        device is power
                        and event.type == ecodes.EV_KEY
                        and event.code == ecodes.KEY_POWER
                        and event.value == 1
                    ):
                        set_display("toggle")
                    elif (
                        device is lid
                        and event.type == ecodes.EV_SW
                        and event.code == ecodes.SW_LID
                    ):
                        set_display("off" if event.value else "on")
    finally:
        power.ungrab()
        power.close()
        lid.close()
  '';

  autoRotate = pkgs.writeShellScriptBin "sheng-niri-auto-rotate" ''
    set -u

    current=""
    ${pkgs.iio-sensor-proxy}/bin/monitor-sensor --accel 2>&1 |
      while IFS= read -r line; do
        transform=""
        case "$line" in
          *"orientation changed: normal"*|*"orientation: normal,"*)
            transform="normal"
            ;;
          *"orientation changed: right-up"*|*"orientation: right-up,"*)
            transform="90"
            ;;
          *"orientation changed: bottom-up"*|*"orientation: bottom-up,"*)
            transform="180"
            ;;
          *"orientation changed: left-up"*|*"orientation: left-up,"*)
            transform="270"
            ;;
        esac

        if [ -n "$transform" ] && [ "$transform" != "$current" ]; then
          runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
          socket="''${NIRI_SOCKET:-}"
          if [ -z "$socket" ]; then
            socket="$(
              ${pkgs.findutils}/bin/find "$runtime_dir" -maxdepth 1 -type s \
                -name 'niri.*.sock' -print 2>/dev/null |
                ${pkgs.coreutils}/bin/head -n 1
            )"
          fi

          if [ -n "$socket" ] &&
             NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg output DSI-1 transform "$transform"; then
            current="$transform"
            ${pkgs.coreutils}/bin/sleep 0.2
            ${pkgs.systemd}/bin/systemctl --user try-restart \
              sheng-niri-touch-gestures.service || true
          fi
        fi
      done
  '';
in
{
  programs.niri.enable = true;
  programs.dconf.enable = true;
  programs.noctalia = {
    enable = true;
    systemd = {
      enable = true;
      target = "niri.service";
    };
    recommendedServices.enable = true;
  };

  services.xserver.enable = lib.mkForce false;
  services.displayManager.gdm.enable = lib.mkForce false;
  services.greetd.settings.default_session = {
    command = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.niri}/bin/niri --config /etc/greetd/niri.kdl";
    user = "greeter";
  };
  programs.regreet = {
    enable = true;
    font = {
      name = "Inter";
      package = pkgs.inter;
      size = 18;
    };
    settings = {
      skip_selection = false;
      GTK = {
        application_prefer_dark_theme = true;
        cursor_blink = false;
      };
      commands = {
        reboot = [
          "${pkgs.systemd}/bin/systemctl"
          "reboot"
        ];
        poweroff = [
          "${pkgs.systemd}/bin/systemctl"
          "poweroff"
        ];
      };
      appearance.greeting_msg = "SHENG";
      widget.clock = {
        format = "%H:%M";
        resolution = "1s";
        label_width = 100;
      };
    };
    extraCss = ''
      window {
        background-color: #101419;
        color: #e8eef3;
      }

      frame.background {
        background-color: #171d24;
        border: 1px solid #34414c;
        border-radius: 8px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.35);
      }

      entry,
      passwordentry,
      combobox > box,
      button {
        min-height: 52px;
        border-radius: 6px;
        padding: 4px 14px;
      }

      entry,
      passwordentry,
      combobox > box {
        background-color: #222b34;
        border: 1px solid #465562;
        color: #f4f7f9;
      }

      entry:focus,
      passwordentry:focus,
      combobox > box:focus {
        border-color: #4dc5dc;
        box-shadow: 0 0 0 2px rgba(77, 197, 220, 0.22);
      }

      button {
        background-color: #27323c;
        border: 1px solid #465562;
        color: #edf2f5;
      }

      button:hover,
      button:focus {
        background-color: #33414d;
        border-color: #60717f;
      }

      button.suggested-action {
        background-color: #4dc5dc;
        border-color: #4dc5dc;
        color: #071014;
      }

      button.destructive-action {
        background-color: #3a292d;
        border-color: #8a4854;
        color: #ffb4be;
      }
    '';
  };
  services.kmscon.enable = lib.mkForce false;
  boot.kernelModules = [ "uinput" ];
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    cliphist
    imagemagick
    jq
    libnotify
    niriDisplay
    niriGestureFeedback
    niriLock
    niriOsk
    niriOskToggle
    niriKey
    niriTouchAction
    niriTouchGestures
    playerctl
    swaybg
    swayidle
    swaylock
    wl-clipboard
    wlsunset
    wvkbd
    wtype
    xwayland-satellite
  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NOCTALIA_CONFIG_HOME = "/etc/xdg";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    SDL_VIDEODRIVER = "wayland";
    TERMINAL = "wezterm";
  };

  environment.shellAliases = {
    nrs = lib.mkForce "nh os switch ~/dotfiles-sheng -H sheng-niri";
    hms = lib.mkForce "nh home switch ~/dotfiles-sheng -c dot@sheng-niri";
  };

  environment.etc = {
    "greetd/niri.kdl".source = regreetNiriConfig;
    "niri/config.kdl".source = ./niri/config.kdl;
    "xdg/swaylock/config".source = ./niri/swaylock.conf;
    "xdg/noctalia/config.toml".source = ./niri/noctalia.toml;
  };

  security.pam.services.swaylock = { };

  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="NVTCapacitiveTouchScreen", GROUP="input", MODE="0660", SYMLINK+="input/touchscreen"
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  # The upstream helper talks directly to Mutter. Niri gets native display
  # control services below instead.
  systemd.services.fake-tablet-mode.wantedBy = lib.mkForce [ ];

  systemd.user.services.noctalia = {
    environment = {
      NOCTALIA_CONFIG_HOME = "/etc/xdg";
      TERMINAL = "wezterm";
    };
    serviceConfig.RestartSec = 2;
  };

  systemd.user.services.fcitx5-daemon = {
    description = "Fcitx5 input method for the Niri session";
    wantedBy = [ "niri.service" ];
    partOf = [ "niri.service" ];
    after = [
      "niri.service"
      "sheng-niri-osk.service"
    ];
    serviceConfig = {
      ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5 --replace";
      Restart = "on-failure";
      RestartSec = 2;
      UnsetEnvironment = "GTK_IM_MODULE";
    };
  };

  systemd.user.services.sheng-niri-osk = {
    description = "Touch-first Fcitx5 virtual keyboard for Niri";
    wantedBy = [ "niri.service" ];
    partOf = [ "niri.service" ];
    after = [ "niri.service" ];
    before = [ "fcitx5-daemon.service" ];
    environment.GSK_RENDERER = "cairo";
    serviceConfig = {
      ExecStart = "${niriOsk}/bin/sheng-niri-osk";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  systemd.user.services.sheng-niri-osk-input = {
    description = "Low-latency virtual keyboard input for the Niri touch keyboard";
    wantedBy = [ "niri.service" ];
    partOf = [ "niri.service" ];
    after = [ "niri.service" ];
    serviceConfig = {
      ExecStart = niriOskInput;
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  systemd.user.services.sheng-niri-display-controls = {
    description = "Handle sheng power key and cover events in Niri";
    wantedBy = [ "niri.service" ];
    partOf = [ "niri.service" ];
    after = [ "niri.service" ];
    serviceConfig = {
      ExecStart = displayControls;
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.user.services.sheng-niri-auto-rotate = {
    description = "Rotate the sheng DSI display from IIO orientation events";
    wantedBy = [ "niri.service" ];
    partOf = [ "niri.service" ];
    after = [ "niri.service" ];
    serviceConfig = {
      ExecStart = "${autoRotate}/bin/sheng-niri-auto-rotate";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.user.services.sheng-niri-touch-gestures = {
    description = "Handle touchscreen gestures in the sheng Niri session";
    wantedBy = [ "niri.service" ];
    wants = [ "sheng-niri-gesture-feedback.service" ];
    partOf = [ "niri.service" ];
    after = [
      "niri.service"
      "sheng-niri-gesture-feedback.service"
    ];
    serviceConfig = {
      ExecStart = "${niriTouchGestures}/bin/sheng-niri-touch-gestures";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.user.services.sheng-niri-gesture-feedback = {
    description = "Show animated feedback for sheng touchscreen gestures";
    wantedBy = [ "niri.service" ];
    partOf = [ "niri.service" ];
    after = [ "niri.service" ];
    before = [ "sheng-niri-touch-gestures.service" ];
    environment.GSK_RENDERER = "cairo";
    serviceConfig = {
      ExecStart = "${niriGestureFeedback}/bin/sheng-niri-gesture-feedback";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };
}
