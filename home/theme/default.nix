# ---
# Module: Sheng Theme
# Description: Icons, cursors, and dynamic wallpaper palette helpers for GNOME
# Scope: Home Manager
# ---

{ lib, pkgs, ... }:
let
  papirus = pkgs.papirus-icon-theme;

  matugenTemplates = pkgs.runCommand "sheng-matugen-templates" { } ''
    mkdir -p $out

    cat > $out/colors.json <<'EOF'
{
  "base": "{{colors.surface.default.hex}}",
  "mantle": "{{colors.surface_container.default.hex}}",
  "crust": "{{colors.surface_container_low.default.hex}}",
  "surface0": "{{colors.surface_container_low.default.hex}}",
  "surface1": "{{colors.outline.default.hex}}",
  "surface2": "{{colors.surface_variant.default.hex}}",
  "overlay0": "{{colors.on_surface_variant.default.hex}}",
  "overlay1": "{{colors.outline.default.hex}}",
  "overlay2": "{{colors.outline_variant.default.hex}}",
  "subtext0": "{{colors.on_surface_variant.default.hex}}",
  "subtext1": "{{colors.on_surface.default.hex}}",
  "text": "{{colors.on_surface.default.hex}}",
  "primary": "{{colors.primary.default.hex}}",
  "primary_dim": "{{colors.primary_container.default.hex}}",
  "primary_soft": "{{colors.primary_fixed.default.hex}}",
  "secondary": "{{colors.secondary.default.hex}}",
  "tertiary": "{{colors.tertiary.default.hex}}",
  "on_primary": "{{colors.on_primary.default.hex}}",
  "red": "{{colors.error.default.hex}}",
  "peach": "{{colors.tertiary.default.hex}}",
  "yellow": "{{colors.primary.default.hex}}",
  "green": "{{colors.secondary.default.hex}}",
  "teal": "{{colors.tertiary.default.hex}}",
  "sky": "{{colors.secondary.default.hex}}",
  "blue": "{{colors.primary.default.hex}}",
  "lavender": "{{colors.secondary.default.hex}}",
  "mauve": "{{colors.primary.default.hex}}",
  "pink": "{{colors.tertiary.default.hex}}"
}
EOF

    cat > $out/nvim_colors.lua <<'EOF'
return {
  base = "{{colors.surface.default.hex}}",
  mantle = "{{colors.surface_container.default.hex}}",
  crust = "{{colors.surface_container_low.default.hex}}",
  surface0 = "{{colors.surface_container_low.default.hex}}",
  surface1 = "{{colors.outline.default.hex}}",
  surface2 = "{{colors.surface_variant.default.hex}}",
  overlay0 = "{{colors.on_surface_variant.default.hex}}",
  overlay1 = "{{colors.outline.default.hex}}",
  overlay2 = "{{colors.outline_variant.default.hex}}",
  text = "{{colors.on_surface.default.hex}}",
  subtext0 = "{{colors.on_surface_variant.default.hex}}",
  subtext1 = "{{colors.on_surface.default.hex}}",
  primary = "{{colors.primary.default.hex}}",
  primary_dim = "{{colors.primary_container.default.hex}}",
  primary_soft = "{{colors.primary_fixed.default.hex}}",
  on_primary = "{{colors.on_primary.default.hex}}",
  secondary = "{{colors.secondary.default.hex}}",
  tertiary = "{{colors.tertiary.default.hex}}",
  red = "{{colors.error.default.hex}}",
  peach = "{{colors.tertiary.default.hex}}",
  yellow = "{{colors.primary.default.hex}}",
  green = "{{colors.secondary.default.hex}}",
  teal = "{{colors.tertiary.default.hex}}",
  sky = "{{colors.secondary.default.hex}}",
  blue = "{{colors.primary.default.hex}}",
  lavender = "{{colors.secondary.default.hex}}",
  mauve = "{{colors.primary.default.hex}}",
  pink = "{{colors.tertiary.default.hex}}",
}
EOF

    cat > $out/wezterm.lua <<'EOF'
return {
  foreground = "{{colors.on_surface.default.hex}}",
  background = "{{colors.surface.default.hex}}",
  cursor_bg = "{{colors.primary.default.hex}}",
  cursor_fg = "{{colors.on_primary.default.hex}}",
  cursor_border = "{{colors.primary.default.hex}}",
  selection_bg = "{{colors.surface_variant.default.hex}}",
  selection_fg = "{{colors.on_surface.default.hex}}",
  scrollbar_thumb = "{{colors.surface_variant.default.hex}}",
  split = "{{colors.outline.default.hex}}",
  ansi = {
    "{{colors.surface_variant.default.hex}}",
    "{{colors.error.default.hex}}",
    "{{colors.secondary.default.hex}}",
    "{{colors.primary.default.hex}}",
    "{{colors.primary.default.hex}}",
    "{{colors.tertiary.default.hex}}",
    "{{colors.secondary.default.hex}}",
    "{{colors.on_surface.default.hex}}",
  },
  brights = {
    "{{colors.outline.default.hex}}",
    "{{colors.error.default.hex}}",
    "{{colors.secondary.default.hex}}",
    "{{colors.primary.default.hex}}",
    "{{colors.primary.default.hex}}",
    "{{colors.tertiary.default.hex}}",
    "{{colors.secondary.default.hex}}",
    "{{colors.on_surface.default.hex}}",
  },
  tab_bar = {
    background = "{{colors.surface_container_low.default.hex}}",
    active_tab = {
      bg_color = "{{colors.primary_container.default.hex}}",
      fg_color = "{{colors.on_primary_container.default.hex}}",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "{{colors.surface_container.default.hex}}",
      fg_color = "{{colors.on_surface_variant.default.hex}}",
    },
    inactive_tab_hover = {
      bg_color = "{{colors.surface_variant.default.hex}}",
      fg_color = "{{colors.on_surface.default.hex}}",
    },
    new_tab = {
      bg_color = "{{colors.surface_container.default.hex}}",
      fg_color = "{{colors.primary.default.hex}}",
    },
  },
}
EOF

    cat > $out/wezterm-frame.lua <<'EOF'
return {
  active_titlebar_bg = "{{colors.surface_container.default.hex}}",
  inactive_titlebar_bg = "{{colors.surface_container_low.default.hex}}",
  active_titlebar_fg = "{{colors.on_surface.default.hex}}",
  inactive_titlebar_fg = "{{colors.on_surface_variant.default.hex}}",
  button_fg = "{{colors.on_surface.default.hex}}",
  button_bg = "{{colors.surface_container.default.hex}}",
  button_hover_fg = "{{colors.on_primary_container.default.hex}}",
  button_hover_bg = "{{colors.primary_container.default.hex}}",
}
EOF

    cat > $out/gtk.css <<'EOF'
@define-color accent_color {{colors.primary.default.hex}};
@define-color accent_bg_color {{colors.primary.default.hex}};
@define-color accent_fg_color {{colors.on_primary.default.hex}};
@define-color destructive_color {{colors.error.default.hex}};
@define-color destructive_bg_color {{colors.error.default.hex}};
@define-color destructive_fg_color {{colors.on_error.default.hex}};
@define-color window_bg_color {{colors.surface.default.hex}};
@define-color window_fg_color {{colors.on_surface.default.hex}};
@define-color view_bg_color {{colors.surface.default.hex}};
@define-color view_fg_color {{colors.on_surface.default.hex}};
@define-color headerbar_bg_color {{colors.surface_container.default.hex}};
@define-color headerbar_fg_color {{colors.on_surface.default.hex}};
@define-color card_bg_color {{colors.surface_container.default.hex}};
@define-color card_fg_color {{colors.on_surface.default.hex}};
EOF

    cat > $out/starship.toml <<'EOF'
palette = "sheng"
add_newline = false
format = "$username$hostname $directory $git_branch$git_status$cmd_duration\n$character"

[palettes.sheng]
primary = "{{colors.primary.default.hex}}"
secondary = "{{colors.secondary.default.hex}}"
tertiary = "{{colors.tertiary.default.hex}}"
error = "{{colors.error.default.hex}}"
surface = "{{colors.surface.default.hex}}"
on_surface = "{{colors.on_surface.default.hex}}"

[username]
show_always = true
format = "[$user]($style)"
style_user = "bold primary"

[hostname]
ssh_only = false
format = "[@$hostname](bold tertiary)"

[directory]
style = "bold secondary"
truncation_length = 5
truncate_to_repo = false

[directory.substitutions]
"sheng-dotfiles" = "sheng-dotfiles"
"Downloads" = "Downloads"
"Documents" = "Documents"
"Pictures" = "Pictures"

[git_branch]
symbol = "git:"
format = " [$symbol$branch]($style)"
style = "bold primary"

[git_status]
format = " [$all_status$ahead_behind]($style)"
style = "bold tertiary"

[cmd_duration]
min_time = 1000
format = " [$duration](secondary)"

[character]
success_symbol = "[>](bold primary)"
error_symbol = "[>](bold error)"
EOF

    cat > $out/zellij.kdl <<'EOF'
themes {
    sheng {
        fg "{{colors.on_surface.default.hex}}"
        bg "{{colors.surface.default.hex}}"
        black "{{colors.surface_variant.default.hex}}"
        red "{{colors.error.default.hex}}"
        green "{{colors.secondary.default.hex}}"
        yellow "{{colors.primary.default.hex}}"
        blue "{{colors.primary.default.hex}}"
        magenta "{{colors.tertiary.default.hex}}"
        cyan "{{colors.secondary.default.hex}}"
        orange "{{colors.tertiary.default.hex}}"
        white "{{colors.on_surface.default.hex}}"
    }
}

theme "sheng"
default_layout "compact"

ui {
    pane_frames {
        rounded_corners true
        hide_session_name true
    }
}
EOF

    cat > $out/opencode-theme.json <<'EOF'
{
  "$schema": "https://opencode.ai/theme.json",
  "defs": {
    "primary": "{{colors.primary.default.hex}}",
    "secondary": "{{colors.secondary.default.hex}}",
    "accent": "{{colors.tertiary.default.hex}}",
    "error": "{{colors.error.default.hex}}",
    "warning": "{{colors.tertiary.default.hex}}",
    "success": "{{colors.secondary.default.hex}}",
    "info": "{{colors.primary.default.hex}}",
    "text": "{{colors.on_surface.default.hex}}",
    "textMuted": "{{colors.on_surface_variant.default.hex}}",
    "background": "{{colors.surface.default.hex}}",
    "backgroundPanel": "{{colors.surface_container.default.hex}}",
    "backgroundElement": "{{colors.surface_variant.default.hex}}",
    "border": "{{colors.outline.default.hex}}",
    "borderActive": "{{colors.primary.default.hex}}",
    "borderSubtle": "{{colors.outline_variant.default.hex}}"
  }
}
EOF

    cat > $out/opencode-tui.json <<'EOF'
{
  "$schema": "https://opencode.ai/tui.json",
  "theme": "sheng",
  "mouse": true
}
EOF
  '';

  matugenConfig = pkgs.writeText "sheng-matugen.toml" ''
    [config]

    [templates.colors_json]
    input_path = "${matugenTemplates}/colors.json"
    output_path = "/home/dot/.cache/sheng-theme/colors.json"

    [templates.neovim]
    input_path = "${matugenTemplates}/nvim_colors.lua"
    output_path = "/home/dot/.cache/sheng-theme/nvim_colors.lua"

    [templates.wezterm]
    input_path = "${matugenTemplates}/wezterm.lua"
    output_path = "/home/dot/.config/wezterm/sheng-theme.lua"

    [templates.wezterm_frame]
    input_path = "${matugenTemplates}/wezterm-frame.lua"
    output_path = "/home/dot/.config/wezterm/sheng-frame.lua"

    [templates.starship]
    input_path = "${matugenTemplates}/starship.toml"
    output_path = "/home/dot/.cache/sheng-theme/starship.toml"

    [templates.zellij]
    input_path = "${matugenTemplates}/zellij.kdl"
    output_path = "/home/dot/.cache/sheng-theme/zellij.kdl"

    [templates.opencode_theme]
    input_path = "${matugenTemplates}/opencode-theme.json"
    output_path = "/home/dot/.config/opencode/themes/sheng.json"

    [templates.opencode_tui]
    input_path = "${matugenTemplates}/opencode-tui.json"
    output_path = "/home/dot/.config/opencode/tui.json"
    post_hook = "pywalfox update >/dev/null 2>&1 || true"
  '';

  shengTheme = pkgs.writeShellApplication {
    name = "sheng-theme";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gnugrep
      gnused
      imagemagick
      jq
      libnotify
      matugen
      python3
      wl-clipboard
      zenity
    ];
    text = ''
      set -euo pipefail

      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/sheng-theme"
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
      wezterm_dir="$config_dir/wezterm"
      opencode_dir="$config_dir/opencode/themes"
      mkdir -p "$cache_dir" "$wezterm_dir" "$opencode_dir"

      usage() {
        cat <<'EOF'
Usage:
  sheng-theme color '#RRGGBB'          Generate a Material You palette from an accent color
  sheng-theme wallpaper /path/img      Set GNOME wallpaper and generate a Material You palette
  sheng-theme pick                     Pick a color from a dialog, copy it, and apply it
  sheng-theme show                     Print the current palette JSON
EOF
      }

      normalize_color() {
        python3 - "$1" <<'PY'
import re
import sys

raw = sys.argv[1].strip()
hex_match = re.fullmatch(r"#?([0-9a-fA-F]{6})", raw)
rgb_match = re.fullmatch(r"rgb\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\)", raw)

if hex_match:
    print("#" + hex_match.group(1).lower())
elif rgb_match:
    parts = [max(0, min(255, int(value))) for value in rgb_match.groups()]
    print("#%02x%02x%02x" % tuple(parts))
else:
    raise SystemExit(f"Unsupported color: {raw}")
PY
      }

      average_color_from_image() {
        local image="$1"
        magick "$image" -resize 1x1\! txt:- \
          | grep -Eom1 '#[0-9A-Fa-f]{6}' \
          | tr '[:upper:]' '[:lower:]'
      }

      sync_gnome_accent() {
        local palette="$cache_dir/colors.json"
        [ -s "$palette" ] || return 0
        command -v gsettings >/dev/null 2>&1 || return 0
        if [ -z "''${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "/run/user/$(id -u)/bus" ]; then
          DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
          export DBUS_SESSION_BUS_ADDRESS
        fi
        gsettings writable org.gnome.desktop.interface accent-color >/dev/null 2>&1 || return 0

        local accent_name
        accent_name="$(
          python3 - "$palette" <<'PY'
import colorsys
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    primary = json.load(handle).get("primary", "#cba6f7").lstrip("#")

r, g, b = [int(primary[i:i + 2], 16) / 255 for i in (0, 2, 4)]
hue = colorsys.rgb_to_hsv(r, g, b)[0] * 360

accents = [
    ("red", 0),
    ("orange", 30),
    ("yellow", 55),
    ("green", 125),
    ("teal", 175),
    ("blue", 220),
    ("purple", 275),
    ("pink", 325),
]

def distance(a, b):
    diff = abs(a - b) % 360
    return min(diff, 360 - diff)

print(min(accents, key=lambda item: distance(hue, item[1]))[0])
PY
        )"
        gsettings set org.gnome.desktop.interface accent-color "'$accent_name'" >/dev/null 2>&1 || true
      }

      fallback_palette() {
        local accent="$1"
        python3 - "$accent" "$cache_dir" "$wezterm_dir" <<'PY'
import colorsys
import json
import pathlib
import sys

accent_raw, cache_dir_raw, wezterm_dir_raw = sys.argv[1:4]
cache_dir = pathlib.Path(cache_dir_raw)
wezterm_dir = pathlib.Path(wezterm_dir_raw)

def rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))

def hx(value):
    return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in value)

def mix(a, b, amount):
    ar, ag, ab = rgb(a)
    br, bg, bb = rgb(b)
    return hx((ar * (1 - amount) + br * amount, ag * (1 - amount) + bg * amount, ab * (1 - amount) + bb * amount))

def shift_hue(color, degrees):
    r, g, b = [v / 255 for v in rgb(color)]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    h = (h + degrees / 360) % 1
    nr, ng, nb = colorsys.hls_to_rgb(h, l, s)
    return hx((nr * 255, ng * 255, nb * 255))

def luminance(color):
    def linear(channel):
        value = channel / 255
        return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4
    r, g, b = [linear(v) for v in rgb(color)]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

accent = accent_raw.lower()
base = "#1e1e2e"
text = "#cdd6f4"
secondary = shift_hue(accent, 32)
tertiary = shift_hue(accent, -42)
palette = {
    "base": base, "mantle": "#181825", "crust": "#11111b", "surface0": "#313244",
    "surface1": "#45475a", "surface2": "#585b70", "overlay0": "#6c7086",
    "overlay1": "#7f849c", "overlay2": "#9399b2", "subtext0": "#a6adc8",
    "subtext1": "#bac2de", "text": text, "primary": accent,
    "primary_dim": mix(accent, base, 0.45), "primary_soft": mix(accent, text, 0.75),
    "secondary": secondary, "tertiary": tertiary,
    "on_primary": "#11111b" if luminance(accent) > 0.45 else text,
    "red": "#f38ba8", "peach": "#fab387", "yellow": "#f9e2af", "green": "#a6e3a1",
    "teal": "#94e2d5", "sky": "#89dceb", "blue": accent, "lavender": secondary,
    "mauve": accent, "pink": tertiary,
}
cache_dir.mkdir(parents=True, exist_ok=True)
wezterm_dir.mkdir(parents=True, exist_ok=True)
(cache_dir / "colors.json").write_text(json.dumps(palette, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
(cache_dir / "nvim_colors.lua").write_text("return {\n" + "".join(f'  {key} = "{value}",\n' for key, value in palette.items()) + "}\n", encoding="utf-8")
(wezterm_dir / "sheng-theme.lua").write_text("return { foreground = \"%s\", background = \"%s\" }\n" % (palette["text"], palette["base"]), encoding="utf-8")
PY
      }

      run_matugen_color() {
        matugen color hex "$1" \
          --config "${matugenConfig}" \
          --mode dark \
          --type scheme-tonal-spot \
          --quiet \
          --continue-on-error
      }

      run_matugen_image() {
        matugen image "$1" \
          --config "${matugenConfig}" \
          --mode dark \
          --type scheme-tonal-spot \
          --quiet \
          --continue-on-error \
          --fallback-color '#cba6f7'
      }

      apply_color() {
        local color
        color="$(normalize_color "$1")"
        if ! run_matugen_color "$color"; then
          fallback_palette "$color"
        fi
        sync_gnome_accent
        printf '%s\n' "$color" | wl-copy 2>/dev/null || true
        notify-send "Sheng theme" "Material You palette generated from $color" 2>/dev/null || true
        echo "Generated sheng palette from $color"
      }

      case "''${1:-}" in
        color)
          [ "$#" -eq 2 ] || { usage >&2; exit 2; }
          apply_color "$2"
          ;;
        wallpaper)
          [ "$#" -eq 2 ] || { usage >&2; exit 2; }
          image="$(realpath "$2")"
          [ -f "$image" ] || { echo "Wallpaper does not exist: $image" >&2; exit 1; }
          if ! run_matugen_image "$image"; then
            color="$(average_color_from_image "$image")"
            fallback_palette "$color"
          fi
          sync_gnome_accent
          if command -v gsettings >/dev/null 2>&1; then
            gsettings set org.gnome.desktop.background picture-uri "file://$image" >/dev/null 2>&1 || true
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$image" >/dev/null 2>&1 || true
          fi
          notify-send "Sheng theme" "Wallpaper palette generated" 2>/dev/null || true
          ;;
        pick)
          color="$(zenity --color-selection --show-palette --title='Sheng theme color' 2>/dev/null || true)"
          [ -n "$color" ] || exit 0
          apply_color "$color"
          ;;
        show)
          jq . "$cache_dir/colors.json"
          ;;
        -h|--help|help|"")
          usage
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [
    papirus
    pkgs.adw-gtk3
    pkgs.bibata-cursors
    pkgs.hicolor-icon-theme
    pkgs.imagemagick
    pkgs.libnotify
    pkgs.matugen
    pkgs.wl-clipboard
    pkgs.zenity
    shengTheme
  ];

  gtk = {
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = papirus;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 32;
    };
    # Keep libadwaita/GTK4 apps on GNOME's native theme so Settings can render
    # accent-color previews correctly. GTK3 still uses adw-gtk3 above.
    gtk4.theme = null;
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 32;
  };

  home.sessionVariables = {
    STARSHIP_CONFIG = lib.mkForce "/home/dot/.cache/sheng-theme/starship.toml";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "32";
    ZELLIJ_CONFIG_FILE = "/home/dot/.cache/sheng-theme/zellij.kdl";
  };

  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = "Bibata-Modern-Classic";
    gtk-theme = "adw-gtk3";
    icon-theme = "Papirus-Dark";
  };

  home.activation.ensureShengTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.cache/sheng-theme/colors.json" ]; then
      ${shengTheme}/bin/sheng-theme color '#cba6f7' >/dev/null 2>&1 || true
    fi
  '';
}
