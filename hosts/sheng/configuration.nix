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
    noto-fonts-emoji
    # fira-code
  ];

  # 全局系统包 (这里只装最底层的必备工具，应用软件建议丢进 home.nix)
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
  ];

  # === 彻底覆盖上游的默认配置 ===
  # 注意：为了不破坏上游 Home Manager 的构建逻辑，我们保留底层自动生成的 luser 账号，但不再使用它。

  
  # 2. 创建你专属的 dot 账号，密码设为 1
  users.users.dot = {
    isNormalUser = true;
    description = "dot";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "input" "render" ];
    password = "1";
  };

  # 3. 强制把开机自动登录账号改为 dot
  services.getty.autologinUser = pkgs.lib.mkForce "dot";

  # 你还可以在这里添加其他系统级的服务
  # 比如 SSH、Docker、Tailscale 等
  # services.openssh.enable = true;

  # 不要修改这里的 stateVersion
  system.stateVersion = "24.05";
}
