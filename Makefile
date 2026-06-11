.PHONY: nrs hms update

# nixos-rebuild switch: 部署整个操作系统的系统级配置（需要 root）
nrs:
	sudo nixos-rebuild switch --flake .#sheng

# home-manager switch: 部署用户级的应用和环境（不需要 root）
hms:
	home-manager switch --flake .#luser@sheng

# 更新 inputs（比如拉取上游 xiaomi-sheng 的最新硬件修复）
update:
	nix flake update
