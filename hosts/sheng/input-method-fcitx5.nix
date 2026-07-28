# ---
# Module: Niri Chinese Input Method
# Description: Provide Fcitx5 with Rime Ice for the Niri Wayland session
# Scope: Host
# ---
{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      qt6Packages.fcitx5-chinese-addons
      fcitx5-gtk
      (fcitx5-rime.override {
        rimeDataPkgs = [ rime-ice ];
      })
    ];
  };

  environment.sessionVariables = {
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "fcitx";
  };
}
