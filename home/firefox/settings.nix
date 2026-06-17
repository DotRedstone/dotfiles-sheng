# ---
# Module: Firefox Settings
# Description: Performance, behavior, and typography overrides
# Scope: Home Manager
# ---

{ config, ... }: {
  programs.firefox.profiles.dot.settings = {
    # [Locale & UI]
    "intl.locale.requested" = "zh-CN";
    "browser.startup.page" = 3; # Restore previous session
    "browser.tabs.loadInBackground" = false; # Switch to new tabs immediately
    "browser.tabs.insertRelatedAfterCurrent" = true;
    "ui.systemUsesDarkTheme" = 1;

    # [Vertical Tabs - 2026 Modern UI]
    "sidebar.verticalTabs" = true;
    "sidebar.revamp" = true;

    # [Typography]
    # Mirror the main dotfiles font stack: Inter/LXGW for text, Maple for code.
    "font.name.sans-serif.zh-CN" = "LXGW Neo XiHei";
    "font.name.serif.zh-CN" = "LXGW WenKai";
    "font.name.monospace.zh-CN" = "Maple Mono NF";
    "font.default.zh-CN" = "sans-serif";

    "font.name.sans-serif.x-western" = "Inter";
    "font.name.serif.x-western" = "LXGW WenKai";
    "font.name.monospace.x-western" = "Maple Mono NF";
    "font.default.x-western" = "sans-serif";

    # [Downloads]
    "browser.download.dir" = "${config.home.homeDirectory}/Downloads";
    "browser.download.folderList" = 2;

    # [Wayland / Mixed DPI]
    # Avoid toolbar popup offset and jumpiness on mixed-scale outputs.
    "widget.wayland.fractional-scale.enabled" = false;

    # [Privacy & Behavior]
    "general.autoScroll" = true;
    "signon.rememberSignons" = false; # Use a password manager instead
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # Enable userChrome.css

    # [Performance]
    "gfx.webrender.all" = true; # Force hardware acceleration
    "media.ffmpeg.vaapi.enabled" = true; # Video hardware decoding
  };
}
