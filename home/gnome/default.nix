# ---
# Module: GNOME Touch Desktop
# Description: Language, fonts, and GNOME defaults for the sheng tablet profile
# Scope: Home Manager
# ---

{ lib, pkgs, ... }:
let
  optionalPackage = name:
    lib.optional
      (lib.hasAttr name pkgs && lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.${name})
      pkgs.${name};
in
{
  home.language = {
    base = "zh_CN.UTF-8";
    ctype = "zh_CN.UTF-8";
    messages = "zh_CN.UTF-8";
    time = "zh_CN.UTF-8";
  };

  home.sessionVariables = {
    LANG = "zh_CN.UTF-8";
    LANGUAGE = "zh_CN:zh";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    cantarell-fonts
  ]
  ++ optionalPackage "source-han-sans"
  ++ optionalPackage "source-han-serif";

  gtk = {
    enable = true;
    font = {
      name = "Noto Sans CJK SC";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-enable-animations = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-enable-animations = 1;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-show-weekday = true;
      cursor-size = 32;
      document-font-name = "Noto Serif CJK SC 11";
      enable-animations = true;
      font-name = "Noto Sans CJK SC 11";
      monospace-font-name = "Noto Sans Mono CJK SC 11";
      show-battery-percentage = true;
      text-scaling-factor = 1.15;
      toolbar-icons-size = "large";
    };

    "org/gnome/desktop/a11y/applications" = {
      screen-keyboard-enabled = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "";
    };

    "org/gnome/mutter" = {
      edge-tiling = true;
    };
  };
}
