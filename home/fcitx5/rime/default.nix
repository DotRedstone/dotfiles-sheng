# ---
# Module: Rime Entry
# Description: Main entry point for Rime input method and schema management
# Scope: Home Manager
# ---

{ lib, pkgs, ... }: {
  imports = [
    ./data.nix
    ./schema.nix
    ./lua
  ];

  home.file.".local/share/fcitx5/rime/rime_ice.custom.yaml".source =
    (pkgs.formats.yaml { }).generate "rime_ice.custom.yaml" {
      patch = import ./patches { inherit lib; };
    };

  home.activation.rimeSyncPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    sync_root="$HOME/.local/share/fcitx5/rime/sync"
    if [ -d "$sync_root" ]; then
      ${pkgs.findutils}/bin/find "$sync_root" -type f \
        -exec ${pkgs.coreutils}/bin/chmod u+w {} +
    fi
  '';
}
