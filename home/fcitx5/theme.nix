# ---
# Module: Fcitx5 Theming
# Description: Classic UI configuration with Mellow & Inflex Themes
# Scope: Home Manager
# ---

{ lib, ... }:
# let
#   # 1. Fetch Mellow themes
#   mellowThemes = pkgs.fetchFromGitHub {
#     owner = "sanweiya";
#     repo = "fcitx5-mellow-themes";
#     rev = "a66028fe22daa81df20e7aac1575918347b60a40";
#     sha256 = "0zg2c42lqbng8kb36w5basjj52jmk9ra050kzh011czp25k8k59m";
#   };
#
#   # 2. Fetch Inflex themes
#   inflexThemes = pkgs.fetchFromGitHub {
#     owner = "sanweiya";
#     repo = "fcitx5-inflex-themes";
#     rev = "master";
#     sha256 = "12rngpcv3ly2d38vcvi9gja5rdfgy2rjhndf0g3y8jp7pn49dh43";
#   };
# in
let
  staticThemes = lib.listToAttrs (
    map
      (theme: {
        name = ".local/share/fcitx5/themes/${theme.name}";
        value = {
          source = theme.source;
          recursive = true;
        };
      })
      [
        {
          name = "OriDark";
          source = ./ori-theme/OriDark;
        }
        {
          name = "OriLight";
          source = ./ori-theme/OriLight;
        }
        {
          name = "noctalia-mellow";
          source = ./custom-themes/noctalia-mellow;
        }
        {
          name = "noctalia-mellow-dark";
          source = ./custom-themes/noctalia-mellow-dark;
        }
        {
          name = "noctalia-inflex";
          source = ./custom-themes/noctalia-inflex;
        }
        {
          name = "noctalia-inflex-dark";
          source = ./custom-themes/noctalia-inflex-dark;
        }
      ]
  );
in
{
  home.activation.fcitx5ClassicUiConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    conf="$HOME/.config/fcitx5/conf/classicui.conf"
    mkdir -p "$(dirname "$conf")"

    # Convert symlink to real file to allow Fcitx5 GUI to save changes
    if [ -L "$conf" ]; then
      tmp="$(mktemp "$conf.XXXXXX")"
      cat "$conf" > "$tmp" || true
      rm -f "$conf"
      mv "$tmp" "$conf"
    fi

    # Initialize file with defaults if it doesn't exist
    if [ ! -f "$conf" ]; then
      printf '%s\n' \
        'Vertical Candidate List=False' \
        'Theme=noctalia-inflex-dark' \
        'Font="Maple Mono NF 14"' \
        'MenuFont="Maple Mono NF 14"' \
        'TrayFont="Maple Mono NF 11"' \
        > "$conf"
    fi

    # Ensure required keys exist without overwriting user-modified values
    grep -q '^Vertical Candidate List=' "$conf" || printf '%s\n' 'Vertical Candidate List=False' >> "$conf"
    grep -q '^Theme=' "$conf" || printf '%s\n' 'Theme=noctalia-inflex-dark' >> "$conf"
    grep -q '^Font=' "$conf" || printf '%s\n' 'Font="Maple Mono NF 14"' >> "$conf"
    grep -q '^MenuFont=' "$conf" || printf '%s\n' 'MenuFont="Maple Mono NF 14"' >> "$conf"
    grep -q '^TrayFont=' "$conf" || printf '%s\n' 'TrayFont="Maple Mono NF 11"' >> "$conf"
  '';

  home.file = {
    # Keep generated theme directories as normal writable directories for
    # Noctalia user templates.
    ".local/share/fcitx5/themes/noctalia-mellow-sync/.hm-keep".text = "";
    ".local/share/fcitx5/themes/noctalia-mellow-dark-sync/.hm-keep".text = "";
    ".local/share/fcitx5/themes/noctalia-inflex-sync/.hm-keep".text = "";
    ".local/share/fcitx5/themes/noctalia-inflex-dark-sync/.hm-keep".text = "";
  }
  // staticThemes;
}
