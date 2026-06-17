# ---
# Module: Node.js Ecosystem
# Description: Node runtime and JavaScript CLI tooling
# Scope: Home Manager
# ---

{ pkgs, ... }: {
  home.packages = with pkgs; [
    nodejs
    pnpm
    gh
  ];
}
