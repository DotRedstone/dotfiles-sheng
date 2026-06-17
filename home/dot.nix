# ---
# Module: dot's Home Manager Configuration
# Description: Personal user environment, packages, and dotfiles
# Scope: Home Manager
# ---
{ config, pkgs, ... }:

{
  imports = [
    ./apps/minecraft
    ./cli-tools
    ./fish
    ./starship
    ./zellij
    ./wezterm
    ./firefox
    ./fcitx5
    ./telegram
    ./wechat
    ./yazi
    ./nixvim
  ];

  # 注意：在 Home Manager 独立部署模式下，username 和 homeDirectory 是必填项
  home.username = "dot";
  home.homeDirectory = "/home/dot";

  # 用户专属的私人软件包 (不污染系统全局环境)
  home.packages = with pkgs; [
    # 开发工具
    # 常用应用
    gnome-system-monitor # GNOME 原生的系统监视器 (带图形界面)
    snapshot # GNOME 原生相机应用
    resources # GNOME 风格的资源与性能监视器
    gnome-console # GNOME 默认终端模拟器
    btop # 最强悍酷炫的终端性能监视工具
  ];

  # Git 配置
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "dot";
        email = "dot@example.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  # 你也可以在这里配置 bash / zsh
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      # 在 dotfiles 仓库目录内使用，避免依赖固定的 clone 路径。
      nrs = "sudo nixos-rebuild switch --flake .#sheng";
      hms = "home-manager switch --flake .#dot@sheng";
    };
  };

  # 桌面美化和 GTK/GNOME 设置也可以写在这里
  # dconf.settings = { ... };

  # 不要修改这里的 stateVersion
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
