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
