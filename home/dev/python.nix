# ---
# Module: Python Development
# Description: Python interpreter and modern static analysis tooling
# Scope: Home Manager
# ---

{ pkgs, ... }: {
  home.packages = with pkgs; [
    python3
    pyright
    ruff
  ];
}
