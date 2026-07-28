# ---
# Module: sheng Niri Home
# Description: User applications, defaults, and input method for the Niri profile
# Scope: Home Manager
# ---
{ pkgs, ... }:

{
  imports = [
    ./fcitx5
    ./firefox
    ./nautilus
    ./wezterm
  ];

  home = {
    username = "dot";
    homeDirectory = "/home/dot";
    stateVersion = "24.05";
    packages = with pkgs; [
      gnome-text-editor
      xdg-terminal-exec
    ];
  };

  programs.home-manager.enable = true;

  gtk = {
    enable = true;
    font = {
      name = "Inter";
      size = 11;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    clock-show-weekday = true;
    color-scheme = "prefer-dark";
    cursor-size = 32;
    document-font-name = "Noto Serif CJK SC 11";
    font-name = "Inter 11";
    monospace-font-name = "Maple Mono NF 11";
    show-battery-percentage = true;
    text-scaling-factor = 1.05;
  };

  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = [ "org.gnome.TextEditor.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
      };
    };
    configFile."xdg-terminals.list".text = ''
      org.wezfurlong.wezterm.desktop
    '';
  };
}
