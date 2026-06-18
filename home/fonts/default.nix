# ---
# Module: User Fonts
# Description: Installs local user fonts that are not available from nixpkgs
# Scope: Home Manager
# ---

{ lib, pkgs, ... }: {
  home.file = {
    ".local/share/fonts/mfga-selfuse/SELFUSE-300.ttf".source = ./mfga-selfuse/SELFUSE-300.ttf;
    ".local/share/fonts/mfga-selfuse/SELFUSE-400.ttf".source = ./mfga-selfuse/SELFUSE-400.ttf;
    ".local/share/fonts/mfga-selfuse/SELFUSE-700.ttf".source = ./mfga-selfuse/SELFUSE-700.ttf;
  };

  home.activation.refreshMfgaFontCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${pkgs.fontconfig}/bin/fc-cache -f "$HOME/.local/share/fonts/mfga-selfuse" >/dev/null 2>&1 || true
  '';
}
