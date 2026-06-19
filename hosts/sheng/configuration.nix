# ---
# Module: Personal System Configuration
# Description: Override and extend the upstream BSP with personal system settings
# Scope: System
# ---
{ config, pkgs, ... }:

{
  # 网络与时区 (使用 mkForce 强行覆盖上游硬件库中设置的默认值)
  networking.hostName = pkgs.lib.mkForce "nixos-sheng";
  time.timeZone = pkgs.lib.mkForce "Asia/Shanghai";
  i18n.defaultLocale = pkgs.lib.mkForce "zh_CN.UTF-8";

  # 字体配置 (如果你需要安装私人中文字体、编程字体等)
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    # fira-code
  ];

  # 全局系统包 (这里只装最底层的必备工具，应用软件建议丢进 home.nix)
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    nh
    nix-output-monitor
  ];

  # 覆盖公开 rootfs 里面面向上游开发仓库的旧快捷命令。
  # 使用时先 cd 到本 dotfiles 仓库，再执行 nrs / hms。
  environment.shellAliases = {
    nrs = "nh os switch ~/sheng-dotfiles";
    hms = "nh home switch ~/sheng-dotfiles";
  };

  # === 彻底隐藏上游的默认配置 ===
  # 为了不破坏上游 Home Manager 的构建逻辑（它需要 /home/luser），
  # 我们强行保留它的家目录，但把它降级为系统底层账户（非普通用户），
  # 这样它就会被彻底踢出图形登录界面！
  users.users.luser.isNormalUser = pkgs.lib.mkForce false;
  users.users.luser.home = pkgs.lib.mkForce "/home/luser";

  # 1. 启用 fish 作为系统 shell
  programs.fish.enable = true;

  # 2. 创建你专属的 dot 账号，密码设为 1
  users.users.dot = {
    isNormalUser = true;
    description = "dot";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "input" "render" ];
    password = "1";
    shell = pkgs.fish;
  };

  # 3. 强制把开机自动登录账号改为 dot
  services.getty.autologinUser = pkgs.lib.mkForce "dot";

  # 你还可以在这里添加其他系统级的服务
  # 比如 SSH、Docker、Tailscale 等
  # services.openssh.enable = true;

  # === 分配 Swap (虚拟内存) ===
  # 为了防止跑大型重度应用（比如带一堆 Mod 的 Minecraft）时内存爆满闪退
  # 这里在系统盘分配 8GB 的动态 Swap 文件
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8192; # 8192 MB = 8 GB
    }
  ];
}
