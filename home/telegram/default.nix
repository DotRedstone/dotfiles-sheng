# ---
# Module: Telegram
# Description: Official Telegram Desktop client with Wayland and QT input optimizations
# Scope: Home Manager
# ---

{ lib, pkgs, ... }: {
  # [Packages]
  home.packages =
    lib.optional
      (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.telegram-desktop)
      pkgs.telegram-desktop;

  # [Environment Variables]
  # Optimized for Wayland and GNOME IBus Chinese input
  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_IM_MODULE = "ibus";
  };
}
