# ---
# Module: GNOME Shell Touch Extensions
# Description: Tablet-friendly GNOME Shell extensions and defaults
# Scope: Home Manager
# ---

{ pkgs, ... }:
let
  extensions = with pkgs.gnomeExtensions; [
    appindicator
    caffeine
    dash-to-dock
    quick-settings-tweaker
    tiling-assistant
    touchup
  ];
in
{
  programs.gnome-shell = {
    enable = true;
    extensions = map (package: { inherit package; }) extensions;
  };

  dconf.settings = {
    "org/gnome/shell/extensions/touchup" = {
      navigation-bar-enabled = true;
      navigation-bar-mode = "gestures";
      navigation-bar-gestures-reserve-space = true;
      navigation-bar-gestures-invisible-mode = "never";
      desktop-background-gestures-enabled = true;
      overview-background-gestures-enabled = true;
      window-preview-gestures-enabled = true;
      osk-key-popups-enabled = true;
      osk-key-popups-style = "accent";
      osk-gestures-swipe-to-close-enabled = true;
      osk-gestures-extend-keys-enabled = true;
      osk-quick-paste-action-enabled = true;
      osk-space-bar-ime-switching-enabled = true;
      screen-rotate-utils-floating-screen-rotate-button-enabled = true;
      double-tap-to-sleep-enabled = true;
      notification-gestures-enabled = true;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      autohide = true;
      intellihide = true;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      require-pressure-to-show = false;
      show-delay = 0.05;
      hide-delay = 0.12;
      animation-time = 0.18;
      dash-max-icon-size = 56;
      icon-size-fixed = false;
      extend-height = false;
      height-fraction = 0.88;
      click-action = "focus-or-previews";
      scroll-action = "switch-workspace";
      show-windows-preview = true;
      show-show-apps-button = true;
      show-apps-at-top = false;
      running-indicator-style = "DOTS";
      transparency-mode = "DYNAMIC";
      customize-alphas = true;
      min-alpha = 0.35;
      max-alpha = 0.82;
    };

    "org/gnome/shell/extensions/quick-settings-tweaks" = {
      notifications-enabled = true;
      notifications-compact = false;
      notifications-show-scrollbar = true;
      media-enabled = true;
      media-compact = false;
      volume-mixer-enabled = true;
      volume-mixer-only-playing = false;
      volume-mixer-show-scrollbar = true;
      input-always-show = true;
      input-show-selected = true;
      output-show-selected = true;
      dnd-quick-toggle-enabled = true;
    };

    "org/gnome/shell/extensions/caffeine" = {
      show-toggle = true;
      show-indicator = "only-active";
      enable-fullscreen = true;
      restore-state = true;
    };

    "org/gnome/shell/extensions/tiling-assistant" = {
      enable-tiling-popup = true;
      enable-raise-tile-group = true;
      window-gap = 8;
      single-screen-gap = 8;
      maximize-with-gap = false;
    };
  };
}
