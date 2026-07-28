# ---
# Module: Niri User Configuration
# Description: Install the sheng Niri desktop configuration for dot
# Scope: Home Manager
# ---

{
  xdg.configFile = {
    "niri/config.kdl".source = ../../hosts/sheng/desktop/niri/config.kdl;
    "noctalia/config.toml".source = ../../hosts/sheng/desktop/niri/noctalia.toml;
  };
}
