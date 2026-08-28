{
  description = "dot's personal NixOS and Home Manager configuration";

  inputs = {
    # 官方包源，建议与上游保持一致使用 nixos-unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/d24fe45e9a798317072547fa5d56950607750e68";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 引用 sheng 硬件仓库。普通用户只需要 clone 本仓库，
    # 不需要在本地额外 clone nixos-sheng。
    nixos-sheng = {
      url = "github:DotRedstone/nixos-sheng/882c1253d7adb846154a8d92b40b459664f7c76b?dir=nixos";
      inputs.shengFirmware.follows = "shengFirmware";
    };

    # 避免在设备上通过 GitHub tarball 拉取大固件仓库时遇到截断缓存。
    shengFirmware.url =
      "git+https://github.com/DotRedstone/sheng-firmware-full.git?rev=719086ce25222dcc54920ae12409eb5d4401bbff";
  };

  outputs = { self, nixpkgs, home-manager, nixos-sheng, ... }@inputs:
  let
    system = "aarch64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    # 基础配置模块，所有桌面环境共享
    shengBaseModules = [
      # 传入 inputs，方便在下游 configuration.nix 中随意调用外部 flake
      ({ lib, ... }: {
        _module.args.inputs = inputs;
        # Device-side rebuilds must reuse the kernel, modules, and firmware
        # already installed by the flashed boot/rootfs pair.
        _module.args.stage2Only = lib.mkForce true;
        environment.systemPackages = [
          home-manager.packages.${system}.default
        ];
      })
      # 引入你的专属系统配置
      ./hosts/sheng/configuration.nix
    ];
  in {
    nixosConfigurations = {
      # 1. GNOME 桌面环境 (使用上游预设)
      # 部署命令: nh os switch ~/dotfiles-sheng -H sheng
      sheng = nixos-sheng.lib.${system}.mkShengGnomeSystem (shengBaseModules ++ [
        inputs.home-manager.nixosModules.home-manager
        ./hosts/sheng/input-method.nix
        ({ ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            sharedModules = [ inputs.nixvim.homeModules.nixvim ];
            users.dot = import ./home/dot.nix;
          };
        })
      ]);

      # 2. KDE Plasma 6 桌面环境
      # 部署命令: nh os switch ~/dotfiles-sheng -H sheng-plasma
      sheng-plasma = nixos-sheng.lib.${system}.mkShengSystem (shengBaseModules ++ [
        ./hosts/sheng/desktop/plasma.nix
      ]);

      # 3. Phosh 触屏专研桌面
      # 部署命令: nh os switch ~/dotfiles-sheng -H sheng-phosh
      sheng-phosh = nixos-sheng.lib.${system}.mkShengSystem (shengBaseModules ++ [
        ./hosts/sheng/desktop/phosh.nix
      ]);

      # 4. Hyprland 平铺窗口管理器
      # 部署命令: nh os switch ~/dotfiles-sheng -H sheng-hyprland
      sheng-hyprland = nixos-sheng.lib.${system}.mkShengSystem (shengBaseModules ++ [
        ./hosts/sheng/desktop/hyprland.nix
      ]);

      # 5. Niri 滚动平铺 Wayland 桌面
      # 部署命令: nh os switch ~/dotfiles-sheng -H sheng-niri
      sheng-niri = nixos-sheng.lib.${system}.mkShengSystem (shengBaseModules ++ [
        inputs.home-manager.nixosModules.home-manager
        inputs.noctalia.nixosModules.default
        ./hosts/sheng/input-method-fcitx5.nix
        ./hosts/sheng/desktop/niri.nix
        ({ ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.dot = import ./home/sheng-niri.nix;
          };
        })
      ]);
    };

    # Home Manager 配置：可以通过 `home-manager switch --flake .#dot@sheng` 部署
    homeConfigurations."dot@sheng" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        ./home/dot.nix
        inputs.nixvim.homeModules.nixvim
      ];
    };

    homeConfigurations."dot@sheng-niri" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home/sheng-niri.nix
      ];
    };
  };
}
