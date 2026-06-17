# ---
# Module: C/C++ Development
# Description: Toolchain for systems programming and native builds
# Scope: Home Manager
# ---

{ pkgs, ... }: {
  home.packages = with pkgs; [
    gcc
    gdb
    cmake
    gnumake
    clang-tools
  ];
}
