# ---
# Module: Chinese Input Method
# Description: Provide Fcitx5 with Rime for GNOME sessions
# Scope: Host
# ---
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = [
      pkgs.qt6Packages.fcitx5-chinese-addons
      pkgs.qt6Packages.fcitx5-configtool
      pkgs.fcitx5-gtk
      pkgs.qt6Packages.fcitx5-rime
    ];
  };
}
