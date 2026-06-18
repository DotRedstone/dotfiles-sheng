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
        'Font="FZYJHK B 14"' \
        'MenuFont="FZYJHK B 14"' \
        'TrayFont="FZYJHK B 11"' \
        > "$conf"
    fi

    # The sheng touch profile owns these UI defaults so stale Fcitx settings
    # do not leave the candidate window with a mismatched Chinese font.
    grep -q '^Vertical Candidate List=' "$conf" || printf '%s\n' 'Vertical Candidate List=False' >> "$conf"
    grep -q '^Theme=' "$conf" || printf '%s\n' 'Theme=noctalia-inflex-dark' >> "$conf"
    if grep -q '^Font=' "$conf"; then
      sed -i 's/^Font=.*/Font="FZYJHK B 14"/' "$conf"
    else
      printf '%s\n' 'Font="FZYJHK B 14"' >> "$conf"
    fi
    if grep -q '^MenuFont=' "$conf"; then
      sed -i 's/^MenuFont=.*/MenuFont="FZYJHK B 14"/' "$conf"
    else
      printf '%s\n' 'MenuFont="FZYJHK B 14"' >> "$conf"
    fi
    if grep -q '^TrayFont=' "$conf"; then
      sed -i 's/^TrayFont=.*/TrayFont="FZYJHK B 11"/' "$conf"
    else
      printf '%s\n' 'TrayFont="FZYJHK B 11"' >> "$conf"
    fi

    if [ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "/run/user/$(id -u)/bus" ]; then
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
    fi
    busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui >/dev/null 2>&1 || true
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
