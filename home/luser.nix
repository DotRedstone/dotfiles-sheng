# ---
# Module: dot's Home Manager Configuration
# Description: Personal user environment, packages, and dotfiles
# Scope: Home Manager
# ---
{ config, pkgs, ... }:

{
  imports = [
    ./apps/minecraft
  ];

  # 注意：在 Home Manager 独立部署模式下，username 和 homeDirectory 是必填项
  home.username = "luser";
  home.homeDirectory = "/home/luser";

  # 用户专属的私人软件包 (不污染系统全局环境)
  home.packages = with pkgs; [
    # 开发工具
    jq
    ripgrep
    fzf
    
    # 常用应用
    # firefox
    # neofetch
  ];

  # Git 配置
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "luser";
        email = "luser@example.com";
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
      ll = "ls -l";
      la = "ls -la";
      # 覆盖全局 alias，使其永远指向新的私人 dotfiles 仓库
      nrs = "sudo nixos-rebuild switch --flake /home/luser/sheng-dotfiles#sheng";
      hms = "home-manager switch --flake /home/luser/sheng-dotfiles#luser@sheng";
    };
  };

  # 桌面美化和 GTK/GNOME 设置也可以写在这里
  # dconf.settings = { ... };

  # 不要修改这里的 stateVersion
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
