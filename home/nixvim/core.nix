# ---
# Module: NixVim - Core
# Description: Neovim enablement, aliases, and global variables
# Scope: Home Manager
# ---

{ pkgs, ... }: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = false;
    vimAlias = false;

    withPython3 = true;
    withRuby = false;
    withNodeJs = true;

    extraPackages = with pkgs; [
      gcc
      gnumake
      unzip
      ripgrep
      fd
      git
      curl
      nodejs
    ];

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
      markdown_recommended_style = 0;
    };
  };
}
