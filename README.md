# dotfiles-sheng

Personal NixOS and Home Manager configuration for Xiaomi Pad 6S Pro 12.4
(`sheng`).

This repository imports the published `nixos-sheng` hardware platform from
GitHub. You do not need to clone `nixos-sheng` next to this repository.

## Features

- **Multi-Desktop Environment Support**: Easily switch between GNOME, KDE Plasma, Phosh, and Hyprland without reinstalling the system.
- **Touch & Mobile Optimizations**: Hardware sensors enabled for auto-rotation, native Wayland virtual keyboards configured for Plasma (`maliit`) and Hyprland (`wvkbd`).
- **Memory Optimized**: ZRAM is enabled globally with a 50% threshold to maximize tablet multitasking performance. GNOME background bloat is stripped out by default.

## Available Desktop Profiles

You can seamlessly switch your entire desktop environment by deploying different NixOS configurations defined in this repository:

1. **GNOME (Default)** - `sheng`
   The default upstream experience with tablet gestures.
   *Command*: `nh os switch ~/dotfiles-sheng -H sheng`

2. **KDE Plasma 6** - `sheng-plasma`
   Highly optimized memory usage with excellent Wayland touchscreen support. (Recommended)
   *Command*: `nh os switch ~/dotfiles-sheng -H sheng-plasma`

3. **Phosh** - `sheng-phosh`
   Purism's minimalist touch-first desktop environment based on GNOME technologies.
   *Command*: `nh os switch ~/dotfiles-sheng -H sheng-phosh`

4. **Hyprland** - `sheng-hyprland`
   Extremely lightweight Wayland compositor for advanced power users.
   *Command*: `nh os switch ~/dotfiles-sheng -H sheng-hyprland`

## First deploy

Clone this repository on the tablet, then deploy from inside the repository:

```sh
git clone https://github.com/DotRedstone/dotfiles-sheng.git
cd dotfiles-sheng
nix flake update
sudo nixos-rebuild switch --flake .#sheng-plasma
```

If Nix reports `Truncated tar archive` while fetching firmware, pull the latest
dotfiles and run `nix flake update` again. This repository overrides the
firmware input to use `git+https` instead of GitHub tarball downloads.

After this system configuration is activated, you can use the aliases:
- `nrs` to rebuild the base system
- `hms` to apply Home Manager configurations

Enjoy your multi-desktop optimized tablet experience!
