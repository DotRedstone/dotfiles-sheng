# ---
# Module: Minecraft App Config
# Description: Prism Launcher and Java dependencies for the sheng tablet profile
# Scope: Home Manager
# ---

{ lib, pkgs, ... }:
let
  prismLauncher = pkgs.symlinkJoin {
    name = "prismlauncher-sheng";
    paths = [
      (pkgs.prismlauncher.override {
        jdks = with pkgs; [
          jdk8
          jdk17
          jdk21
          jdk25
        ];
      })
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/prismlauncher \
        --set QT_QPA_PLATFORM xcb \
        --set QT_IM_MODULE ibus \
        --set XMODIFIERS @im=ibus
    '';
  };
in
{
  home.packages = with pkgs; [
    prismLauncher
    xrandr
    glfw
    openal
  ];

  home.activation.removeHmclState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -rf \
      "$HOME/.hmcl" \
      "$HOME/.config/hmcl" \
      "$HOME/.local/share/hmcl" \
      "$HOME/.cache/hmcl" \
      "$HOME/.local/share/HMCL" \
      "$HOME/.cache/HMCL"
  '';
}
