# ---
# Module: Personal System Configuration
# Description: Override and extend the upstream BSP with personal system settings
# Scope: System
# ---
{ config, pkgs, ... }:

{
  # 网络与时区 (使用 mkForce 强行覆盖上游硬件库中设置的默认值)
  networking.hostName = pkgs.lib.mkForce "sheng";
  time.timeZone = pkgs.lib.mkForce "Asia/Shanghai";
  i18n.defaultLocale = pkgs.lib.mkForce "zh_CN.UTF-8";

  # Keep the public image self-contained: UI, Chinese, monospace, symbols,
  # emoji, and document fonts all have an explicit fallback.
  fonts = {
    packages = with pkgs; [
      cantarell-fonts
      inter
      maple-mono.NF
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];

    fontconfig.defaultFonts = {
      sansSerif = [
        "Inter"
        "Noto Sans CJK SC"
        "Noto Sans"
      ];
      serif = [
        "Noto Serif CJK SC"
        "Noto Serif"
      ];
      monospace = [
        "Maple Mono NF"
        "Noto Sans Mono CJK SC"
        "Noto Sans Mono"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # nixos-sheng v0.1.4 ships the sheng UCM package but does not link its
  # /share/alsa payload into the system profile.
  environment.pathsToLink = [ "/share/alsa" ];

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

  # Keep ADB's root shell from resolving ~ to the stale /root clone. Home
  # Manager must run as dot so its profile and generated files keep ownership.
  environment.shellAliases = {
    nrs = "nh os switch /home/dot/dotfiles-sheng -H sheng";
    nrs-niri = "nh os switch /home/dot/dotfiles-sheng -H sheng-niri";
    hms = "${pkgs.util-linux}/bin/runuser -u dot -- ${pkgs.coreutils}/bin/env HOME=/home/dot USER=dot ${pkgs.nh}/bin/nh home switch /home/dot/dotfiles-sheng -c dot@sheng";
  };

  # 在 sheng 上先关闭自动 GC。移动端 rootfs 一旦带 ext4 错误启动，
  # 开机补跑 GC 很容易把 /nix/store 写入压力放大成 emergency read-only。
  nix.gc.automatic = pkgs.lib.mkForce false;

  # === 彻底隐藏上游的默认配置 ===
  # 为了不破坏上游 Home Manager 的构建逻辑（它需要 /home/luser），
  # 我们强行保留它的家目录，但把它降级为系统底层账户（非普通用户），
  # 这样它就会被彻底踢出图形登录界面！
  users.users.luser.isNormalUser = pkgs.lib.mkForce false;
  users.users.luser.isSystemUser = true;
  users.users.luser.group = "luser";
  users.groups.luser = {};
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

  # === 平板触控与传感器优化 ===
  # 开启陀螺仪与重力传感器，以支持屏幕自动旋转 (GNOME, Plasma, Phosh 均可调用)
  hardware.sensor.iio.enable = true;


  # 你还可以在这里添加其他系统级的服务
  # 比如 SSH、Docker、Tailscale 等
  # services.openssh.enable = true;

  # === ZRAM 内存压缩 ===
  # 将空闲的内存进行压缩，变相增加可用内存容量（大幅缓解 8GB/12GB 设备开机内存占用压力）
  zramSwap = {
    enable = true;
    memoryPercent = pkgs.lib.mkForce 50; # 最多使用 50% 内存作为 zram (强制覆盖上游默认的 25%)
  };

  # === 分配 Swap (虚拟内存) ===
  # 为了防止跑大型重度应用（比如带一堆 Mod 的 Minecraft）时内存爆满闪退
  # 这里在系统盘分配 8GB 的动态 Swap 文件
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8192; # 8192 MB = 8 GB
    }
  ];

  # === 精简 GNOME 全家桶 ===
  # 剔除不需要的 GNOME 预装软件，减少后台常驻内存占用
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-weather
    epiphany
    geary
    evince
    gnome-characters
    totem
    tali
    iagno
    hitori
    atomix
    yelp
    gnome-clocks
  ];
}
