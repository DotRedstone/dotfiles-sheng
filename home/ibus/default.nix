# ---
# Module: IBus Touch Input
# Description: Configure GNOME-friendly Chinese input for the tablet touch keyboard
# Scope: Home Manager
# ---

{ lib, ... }:
let
  inherit (lib.hm.gvariant) mkTuple mkUint32;
in
{
  imports = [
    ./rime.nix
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
    SDL_IM_MODULE = "ibus";
    GLFW_IM_MODULE = "ibus";
  };

  xdg.configFile."environment.d/90-ibus.conf".text = ''
    GTK_IM_MODULE=ibus
    QT_IM_MODULE=ibus
    XMODIFIERS=@im=ibus
    SDL_IM_MODULE=ibus
    GLFW_IM_MODULE=ibus
  '';

  dconf.settings."org/gnome/desktop/input-sources" = {
    sources = [
      (mkTuple [ "xkb" "us" ])
      (mkTuple [ "ibus" "rime" ])
    ];
    mru-sources = [
      (mkTuple [ "ibus" "rime" ])
      (mkTuple [ "xkb" "us" ])
    ];
    current = mkUint32 0;
  };
}
