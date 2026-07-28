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
    set -eu

    unit="sheng-niri-osk.service"
    if ${pkgs.systemd}/bin/systemctl --user is-active --quiet "$unit"; then
      ${pkgs.systemd}/bin/systemctl --user stop "$unit"
    else
      ${pkgs.systemd}/bin/systemd-run --user --collect --unit="$unit" \
        ${pkgs.wvkbd}/bin/wvkbd-mobintl -L 300
    fi
  '';

  niriTouchAction = pkgs.writeShellScriptBin "sheng-niri-touch-action" ''
    set -eu

    case "''${1:-}" in
      launcher)
        exec ${lib.getExe config.programs.noctalia.package} msg panel-toggle launcher
        ;;
      control-center)
        exec ${lib.getExe config.programs.noctalia.package} msg panel-toggle control-center
        ;;
      column-left|column-right|workspace-up|workspace-down|overview)
        ;;
      *)
        exit 2
        ;;
    esac

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
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

    case "$1" in
      column-left)
        action="focus-column-left"
        ;;
      column-right)
        action="focus-column-right"
        ;;
      workspace-up)
        action="focus-workspace-up"
        ;;
      workspace-down)
        action="focus-workspace-down"
        ;;
      overview)
        action="toggle-overview"
        ;;
    esac

    NIRI_SOCKET="$socket" ${pkgs.niri}/bin/niri msg action "$action"
  '';

  niriTouchGestures = pkgs.writeShellScriptBin "sheng-niri-touch-gestures" ''
    set -eu

    export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
    action=${niriTouchAction}/bin/sheng-niri-touch-action

    exec ${pkgs.lisgd}/bin/lisgd \
      -d /dev/input/touchscreen \
      -m 1000 \
      -r 20 \
      -t 220 \
      -g "3,RL,*,*,R,$action column-right" \
      -g "3,LR,*,*,R,$action column-left" \
      -g "3,DU,*,*,R,$action workspace-down" \
      -g "3,UD,*,*,R,$action workspace-up" \
      -g "4,DU,*,*,R,$action overview" \
      -g "4,UD,*,*,R,$action overview" \
      -g "4,LR,*,*,R,$action launcher" \
      -g "4,RL,*,*,R,$action control-center"
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

  services.xserver.enable = true;
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.excludePackages = [ pkgs.xterm ];
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "niri";
  services.kmscon.enable = lib.mkForce false;
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    cliphist
    imagemagick
    jq
    libnotify
    lisgd
    niriDisplay
    niriOskToggle
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
    "niri/config.kdl".source = ./niri/config.kdl;
    "xdg/swaylock/config".source = ./niri/swaylock.conf;
    "xdg/noctalia/config.toml".source = ./niri/noctalia.toml;
  };

  security.pam.services.swaylock = { };

  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="NVTCapacitiveTouchScreen", GROUP="input", MODE="0660", SYMLINK+="input/touchscreen"
  '';

  programs.dconf.profiles.gdm.databases = [
    {
      settings."org/gnome/desktop/a11y/applications" = {
        screen-keyboard-enabled = true;
      };
      settings."org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "nothing";
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };
    }
  ];

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
    after = [ "niri.service" ];
    serviceConfig = {
      ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5 --replace";
      Restart = "on-failure";
      RestartSec = 2;
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
    partOf = [ "niri.service" ];
    after = [ "niri.service" ];
    serviceConfig = {
      ExecStart = "${niriTouchGestures}/bin/sheng-niri-touch-gestures";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
