# ---
# Module: Rime Data
# Description: Symlinking external Rime Ice data files
# Scope: Home Manager
# ---

{ lib, pkgs, ... }:
let
  rimeIce = "${pkgs.rime-ice}/share/rime-data";

  linkedDirectories = [
    "cn_dicts"
    "en_dicts"
    "lua"
    "opencc"
  ];

  linkedFiles = [
    "custom_phrase.txt"
    "double_pinyin.schema.yaml"
    "double_pinyin_abc.schema.yaml"
    "double_pinyin_flypy.schema.yaml"
    "double_pinyin_jiajia.schema.yaml"
    "double_pinyin_mspy.schema.yaml"
    "double_pinyin_sogou.schema.yaml"
    "double_pinyin_ziguang.schema.yaml"
    "melt_eng.dict.yaml"
    "melt_eng.schema.yaml"
    "radical_pinyin.dict.yaml"
    "radical_pinyin.schema.yaml"
    "rime_ice.dict.yaml"
    "rime_ice.schema.yaml"
    "rime_ice_suggestion.yaml"
    "symbols_caps_v.yaml"
    "symbols_v.yaml"
    "t9.schema.yaml"
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
    lib.mapAttrs' (name: value: lib.nameValuePair ".local/share/fcitx5/rime/${name}" value)
      (directoryLinks // fileLinks);
}
