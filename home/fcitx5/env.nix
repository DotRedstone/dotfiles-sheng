# ---
# Module: Fcitx5 Environment
# Description: Input method variables for apps without native Wayland text input
# Scope: Home Manager
# ---

{ ... }: {
  home.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "fcitx";
  };

  xdg.configFile."environment.d/90-fcitx5.conf".text = ''
    QT_IM_MODULE=fcitx
    XMODIFIERS=@im=fcitx
    SDL_IM_MODULE=fcitx
    GLFW_IM_MODULE=fcitx
  '';
}
