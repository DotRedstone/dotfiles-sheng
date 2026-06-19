# ---
# Module: dot's Home Manager Configuration
# Description: Personal user environment, packages, and dotfiles
# Scope: Home Manager
# ---

{ pkgs, ... }: {
  imports = [
    ./apps/minecraft
    ./fonts
    ./gnome
    ./theme
    ./dev
    ./cli-tools
    ./fish
    ./starship
    ./zellij
    ./wezterm
    ./firefox
    ./ibus
    ./nautilus
    ./telegram
    ./wechat
    ./yazi
    ./nixvim
  ];

  # Home Manager standalone deployment requires these two values.
  home.username = "dot";
  home.homeDirectory = "/home/dot";

  home.packages = with pkgs; [
    gnome-system-monitor
    snapshot
    resources
    gnome-console
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
      nrs = "nh os switch ~/sheng-dotfiles#sheng";
      hms = "nh home switch ~/sheng-dotfiles#dot@sheng";
    };
  };

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}
