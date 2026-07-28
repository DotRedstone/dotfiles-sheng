# ---
# Module: Niri User Configuration
# Description: Install the sheng Niri desktop configuration for dot
# Scope: Home Manager
# ---

{
  xdg.configFile = {
    "niri/config.kdl".source = ../../hosts/sheng/desktop/niri/config.kdl;
    "waybar/config.jsonc".source = ../../hosts/sheng/desktop/niri/waybar.jsonc;
    "waybar/style.css".source = ../../hosts/sheng/desktop/niri/waybar.css;
    "mako/config".source = ../../hosts/sheng/desktop/niri/mako.conf;
    "fuzzel/fuzzel.ini".source = ../../hosts/sheng/desktop/niri/fuzzel.ini;
    "swaylock/config".source = ../../hosts/sheng/desktop/niri/swaylock.conf;
  };
}
