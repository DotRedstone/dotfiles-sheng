# ---
# Module: dot's Home Manager Configuration
# Description: Personal user environment, packages, and dotfiles
# Scope: Home Manager
# ---

{ config, lib, osConfig ? null, pkgs, ... }:
let
  # The NixOS-integrated tablet profile should remain rebuildable on-device.
  # Large optional applications stay available through the standalone HM output.
  isIntegratedSheng =
    osConfig != null && osConfig.networking.hostName == "sheng";
in
{
  imports = [
    ./fonts
    ./gnome
    ./theme
    ./cli-tools
    ./fish
    ./starship
    ./zellij
    ./firefox
    ./ibus
    ./nautilus
    ./niri
    ./yazi
    ./nixvim
  ] ++ lib.optionals (!isIntegratedSheng) [
    ./apps/minecraft
    ./dev
    ./wezterm
    ./telegram
    ./wechat
  ];

  # Home Manager standalone deployment requires these two values.
  home.username = "dot";
  home.homeDirectory = "/home/dot";

  home.packages = with pkgs; [
    gnome-system-monitor
    snapshot
    resources
    gnome-console
    rnote
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "dot";
        email = "dot@example.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      nrs = "nh os switch /home/dot/dotfiles-sheng -H sheng";
      nrs-niri = "nh os switch /home/dot/dotfiles-sheng -H sheng-niri";
      hms = "nh home switch /home/dot/dotfiles-sheng -c dot@sheng";
    };
  };

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    publicShare = "${config.home.homeDirectory}/Public";
    templates = "${config.home.homeDirectory}/Templates";
    videos = "${config.home.homeDirectory}/Videos";
  };
}
