# ---
# Module: IBus Rime Ice
# Description: Provide Rime Ice schema and customizations for IBus Rime
# Scope: Home Manager
# ---

{ lib, pkgs, ... }:
let
  rimeDir = ".config/ibus/rime";
  rimeIce = "${pkgs.rime-ice}/share/rime-data";

  linkedDirectories = [
    "cn_dicts"
    "en_dicts"
    "lua"
    "opencc"
  ];

  linkedFiles = [
    "custom_phrase.txt"
    "melt_eng.dict.yaml"
    "melt_eng.schema.yaml"
    "radical_pinyin.dict.yaml"
    "radical_pinyin.schema.yaml"
    "rime_ice.dict.yaml"
    "rime_ice.schema.yaml"
    "rime_ice_suggestion.yaml"
    "symbols_caps_v.yaml"
    "symbols_v.yaml"
  ];

  directoryLinks = lib.genAttrs linkedDirectories (name: {
    source = "${rimeIce}/${name}";
    recursive = true;
    force = true;
  });

  fileLinks = lib.genAttrs linkedFiles (name: {
    source = "${rimeIce}/${name}";
    force = true;
  });
in
{
  home.file =
    lib.mapAttrs' (name: value: lib.nameValuePair "${rimeDir}/${name}" value)
      (directoryLinks // fileLinks)
    // {
      "${rimeDir}/default.custom.yaml".source =
        (pkgs.formats.yaml { }).generate "default.custom.yaml" {
          patch = {
            schema_list = [ { schema = "rime_ice"; } ];
            "menu/page_size" = 10;
          };
        };

      "${rimeDir}/rime_ice.custom.yaml".source =
        (pkgs.formats.yaml { }).generate "rime_ice.custom.yaml" {
          patch = import ../fcitx5/rime/patches { inherit lib; };
        };
    };
}
