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
  imports = [
    ./extensions.nix
  ];

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

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ "Inter" "FZYJHK B" "Noto Sans CJK SC" ];
      serif = [ "FZYJHK B" "Noto Serif CJK SC" ];
      monospace = [ "Maple Mono NF" "FZYJHK B" "Sarasa Mono SC" "Noto Sans Mono CJK SC" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  xdg.configFile."fontconfig/conf.d/20-sheng-zh-cn-fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test name="lang">
          <string>zh-cn</string>
        </test>
        <edit name="family" mode="prepend">
          <string>FZYJHK B</string>
        </edit>
      </match>
    </fontconfig>
  '';

  home.packages = with pkgs; [
    maple-mono.NF
    inter
    lxgw-neoxihei
    lxgw-wenkai
    sarasa-gothic
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
      name = "Maple Mono NF";
      size = 12;
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
      document-font-name = "FZYJHK B 12";
      enable-animations = true;
      font-name = "Maple Mono NF 12";
      monospace-font-name = "Maple Mono NF 12";
      show-battery-percentage = true;
      text-scaling-factor = 1.15;
      toolbar-icons-size = "large";
    };

    "org/gnome/desktop/a11y/applications" = {
      screen-keyboard-enabled = true;
      screen-magnifier-enabled = false;
      screen-reader-enabled = false;
    };

    "org/gnome/desktop/a11y/keyboard" = {
      bouncekeys-enable = false;
      mousekeys-enable = false;
      slowkeys-enable = false;
      stickykeys-enable = false;
      togglekeys-enable = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
    };

    "org/gnome/mutter" = {
      edge-tiling = true;
    };
  };
}
