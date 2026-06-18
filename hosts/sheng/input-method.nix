# ---
# Module: Chinese Input Method
# Description: Provide IBus with libpinyin for the GNOME touch keyboard
# Scope: Host
# ---
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [
      libpinyin
    ];
  };
}
