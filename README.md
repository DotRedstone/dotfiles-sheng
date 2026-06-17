# sheng-dotfiles

Personal NixOS and Home Manager configuration for Xiaomi Pad 6S Pro 12.4
(`sheng`).

This repository imports the published `nixos-xiaomi-sheng` hardware platform
from GitHub. You do not need to clone `nixos-xiaomi-sheng` next to this
repository.

## First deploy

Clone this repository on the tablet, then deploy from inside the repository:

```sh
git clone https://github.com/DotRedstone/sheng-dotfiles.git
cd sheng-dotfiles
nix flake update
sudo nixos-rebuild switch --flake .#sheng
```

If Nix reports `Truncated tar archive` while fetching firmware, pull the latest
dotfiles and run `nix flake update` again. This repository overrides the
firmware input to use `git+https` instead of GitHub tarball downloads.

The public rootfs may still provide an old `nrs` shortcut pointing to the
upstream development checkout. For the first deploy, use the full
`nixos-rebuild` command above or run:

```sh
make nrs
```

After this system configuration is activated, `nrs` and `hms` are overridden to
use the current dotfiles directory:

```sh
nrs
hms
```
