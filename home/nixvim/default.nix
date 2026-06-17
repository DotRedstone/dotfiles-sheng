# ---
# Module: NixVim Switchboard
# Description: Unified entry point for atomized Neovim configuration
# Scope: Home Manager
# ---

{ inputs, ... }: {
  programs.nixvim.nixpkgs.source = inputs.nixpkgs;

  imports = [
    ./packages.nix
    ./core.nix
    ./options.nix
    ./diagnostics.nix
    ./keymaps.nix
    ./autocmds.nix
    ./colorscheme.nix
    ./plugins
  ];
}
