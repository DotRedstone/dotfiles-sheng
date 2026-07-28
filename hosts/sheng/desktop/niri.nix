# ---
# Module: Niri Desktop
# Description: Touch-friendly Niri session for Xiaomi Pad 6S Pro
# Scope: System
# ---

{ lib, pkgs, ... }:

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
    niriDisplay
    niriOskToggle
    playerctl
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

  environment.etc = {
    "niri/config.kdl".source = ./niri/config.kdl;
    "xdg/noctalia/config.toml".source = ./niri/noctalia.toml;
  };

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
}
