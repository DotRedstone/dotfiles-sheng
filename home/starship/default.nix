# ---
# Module: Starship
# Description: Minimalist shell prompt with Noctalia dynamic theme integration
# Scope: Home Manager
# ---

{ config, lib, ... }: {

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  # Load static starship toml
  xdg.configFile."starship.toml" = {
    source = ./starship.toml;
  };
}
