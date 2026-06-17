# ---
# Module: Script Runtime Directories
# Description: Standard user script layout and PATH for shell, Node, and Python helpers
# Scope: Home Manager
# ---

{ config, lib, ... }:
let
  homeDir = config.home.homeDirectory;
  scriptBase = "${homeDir}/.local/scripts";
in
{
  home.sessionPath = [
    "${scriptBase}/bin"
    "${scriptBase}/node/bin"
    "${scriptBase}/python/bin"
  ];

  home.activation.ensureScriptRuntimeDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${scriptBase}/bin"
    mkdir -p "${scriptBase}/node/bin"
    mkdir -p "${scriptBase}/python/bin"
    mkdir -p "${scriptBase}/logs"
  '';
}
