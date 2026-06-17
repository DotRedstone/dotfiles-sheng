# ---
# Module: Development Entry
# Description: Aggregated CLI development environments for sheng
# Scope: Home Manager
# ---

{
  imports = [
    ./cpp.nix
    ./java.nix
    ./node.nix
    ./python.nix
    ./scripts-runtime.nix
  ];
}
