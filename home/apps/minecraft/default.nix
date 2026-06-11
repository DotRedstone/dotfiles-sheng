# ---
# Module: Minecraft App Config
# Description: Minecraft launchers and Java dependencies
# Scope: Home Manager
# ---
{ config, pkgs, ... }:

{
  # 将依赖的软件包统一写在这里
  home.packages = with pkgs; [
    # 首推 PrismLauncher：开源、原生支持 Linux 和 Wayland，管理多实例和 Mod 极其方便
    prismlauncher

    # 同时也备用一个 HMCL，适合国内习惯
    hmcl

    # === 运行环境 (Java) ===
    # Minecraft 不同版本需要不同版本的 Java，我们全给装上
    jdk8    # 适用于 1.12.2 及以下老版本
    jdk17   # 适用于 1.17 - 1.20.4
    jdk21   # 适用于 1.20.5 及以上最新版本
    
    # 依赖工具（有些 Mod 或者启动器需要用到）
    xrandr
    glfw
    openal
  ];

  # 你还可以在这里添加启动器的特定配置文件，比如自动把配置文件链接到 ~/.local/share/PrismLauncher 
  # 保持目录的高度模块化
}
