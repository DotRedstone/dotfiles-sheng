# ---
# Module: GNOME Shell Touch Extensions
# Description: Tablet-friendly GNOME Shell extensions and defaults
# Scope: Home Manager
# ---

{ pkgs, ... }:
let
  gjsOsk = pkgs.stdenvNoCC.mkDerivation {
    pname = "gnome-shell-extension-gjs-osk";
    version = "375b7db";

    src = pkgs.fetchurl {
      url = "https://github.com/Vishram1123/gjs-osk/releases/download/375b7db/gjsosk%40vishram1123_main.zip";
      hash = "sha256-VXuIOgt046Cy8rf0EctMgBRrGiVAPmKOXmAgX//CMoM=";
    };

    nativeBuildInputs = [
      pkgs.glib
      pkgs.unzip
    ];

    unpackPhase = ''
      runHook preUnpack
      mkdir source
      unzip "$src" -d source
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      uuid="gjsosk@vishram1123.com"
      extension_dir="$out/share/gnome-shell/extensions/$uuid"
      mkdir -p "$extension_dir"
      cp -r source/* "$extension_dir/"
      glib-compile-schemas "$extension_dir/schemas"
      runHook postInstall
    '';

    passthru = {
      extensionUuid = "gjsosk@vishram1123.com";
      extensionPortalSlug = "gjs-osk";
    };
  };

  extensions = with pkgs.gnomeExtensions; [
    appindicator
    caffeine
    quick-settings-tweaker
    tiling-assistant
    dash-to-dock
  ] ++ [
    gjsOsk
  ];
in
{
  home.packages = [
    gjsOsk
  ];

  xdg.dataFile."gnome-shell/extensions/gjsosk@vishram1123.com" = {
    source = "${gjsOsk}/share/gnome-shell/extensions/gjsosk@vishram1123.com";
    recursive = true;
    force = true;
  };

  programs.gnome-shell = {
    enable = true;
    extensions = map (package: { inherit package; }) extensions;
  };

  dconf.settings = {
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

    "org/gnome/shell/extensions/gjsosk" = {
      layout-landscape = 0;
      layout-portrait = 0;
      landscape-width-percent = 72;
      landscape-height-percent = 28;
      portrait-width-percent = 92;
      portrait-height-percent = 30;
      disable-edge-swipe = false;
      enable-drag = true;
      default-snap = 7;
      indicator-enabled = true;
      enable-tap-gesture = 1;
      enable-key-repeat = true;
      key-repeat-rate = 71;
      play-sound = true;
      show-icons = true;
      round-key-corners = true;
      font-size-px = 17;
      font-bold = false;
      border-spacing-px = 5;
      outer-spacing-px = 10;
      snap-spacing-px = 28;
      system-accent-col = false;
      background-r-dark = 28.0;
      background-g-dark = 28.0;
      background-b-dark = 34.0;
      background-a-dark = 0.92;
      background-r = 245.0;
      background-g = 245.0;
      background-b = 248.0;
      background-a = 0.96;
    };

    "org/gnome/shell/extensions/gjsosk/indicator" = {
      opened = false;
      keyboard-visible = false;
    };
  };
}
