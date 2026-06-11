# ---
# Module: Minecraft App Config
# Description: Minecraft launchers and Java dependencies
# Scope: Home Manager
# ---
{ config, pkgs, ... }:

{
  # 将依赖的软件包统一写在这里
  home.packages = with pkgs; [
    # 首推 PrismLauncher：原生支持 Wayland。
    # 巧妙利用 override，将所有版本的 Java 环境悄悄注入给启动器内部，而不是全局安装（防止不同版本的 java 命令冲突）
    (prismlauncher.override {
      jdks = [
        jdk8
        jdk17
        jdk21
        jdk25
      ];
    })

    # 同时也备用一个 HMCL，适合国内习惯
    hmcl

    # 依赖工具（有些 Mod 或者启动器需要用到）
    xrandr
    glfw
    openal
  ];

  # 你还可以在这里添加启动器的特定配置文件，比如自动把配置文件链接到 ~/.local/share/PrismLauncher 
  # 保持目录的高度模块化
}
