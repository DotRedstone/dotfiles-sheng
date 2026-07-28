# ---
# Module: Niri Chinese Input Method
# Description: Provide Fcitx5 with Rime Ice for the Niri Wayland session
# Scope: Host
# ---
{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (_final: prev: {
      qt6Packages = prev.qt6Packages.overrideScope (_qtFinal: qtPrev: {
        fcitx5-with-addons = qtPrev.fcitx5-with-addons.override {
          withConfigtool = false;
        };
      });
    })
  ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      (fcitx5-rime.override {
        rimeDataPkgs = [
          rime-data
          rime-ice
        ];
      })
    ];
  };

  environment.sessionVariables = {
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "fcitx";
  };
}
