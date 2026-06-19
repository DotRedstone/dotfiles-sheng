# ---
# Module: Nautilus Settings
# Description: Touch-friendly file manager defaults and file associations
# Scope: Home Manager
# ---

{ config, ... }:

{
  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
      migrated-gtk-settings = true;
      search-filter-time-type = "last_modified";
    };

    "org/gnome/nautilus/icon-view" = {
      default-zoom-level = "large";
    };

    "org/gnome/nautilus/compression" = {
      default-compression-format = "zip";
      full-path = true;
    };
  };

  gtk.gtk3.bookmarks = [
    "file://${config.home.homeDirectory}/Downloads 下载"
    "file://${config.home.homeDirectory}/Pictures 图片"
    "file://${config.home.homeDirectory}/Videos 视频"
    "file://${config.home.homeDirectory}/Documents 文档"
    "file://${config.home.homeDirectory}/Music 音乐"
    "file://${config.home.homeDirectory}/dotfiles-sheng Sheng Dotfiles"
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/pdf" = [ "org.gnome.Evince.desktop" ];
      "image/png" = [ "org.gnome.Loupe.desktop" ];
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      "image/webp" = [ "org.gnome.Loupe.desktop" ];
    };
  };
}
