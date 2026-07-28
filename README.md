# dotfiles-sheng

Personal NixOS and Home Manager configuration for Xiaomi Pad 6S Pro 12.4
(`sheng`).

This repository imports the published `nixos-sheng` hardware platform from
GitHub. You do not need to clone `nixos-sheng` next to this repository.

## Features

- **Multi-Desktop Environment Support**: Easily switch between GNOME, KDE Plasma, Phosh, Hyprland, and Niri without reinstalling the system.
- **Touch & Mobile Optimizations**: Hardware sensors enabled for auto-rotation, with native Wayland virtual keyboards and touch controls for alternative desktops.
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

5. **Niri** - `sheng-niri`
   Scrollable tiling Wayland compositor with a sheng-specific 2x display
   layout, touch controls, on-screen keyboard, automatic rotation, and cover
   handling.
   *Command*: `nh os switch ~/dotfiles-sheng -H sheng-niri`

## Performance & Storage Metrics

Here is the NixOS closure size footprint for each desktop environment configuration (compiled natively for `aarch64-linux`):

| Desktop Environment | Profile Name | System Closure Size | Status | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **GNOME** | `sheng` | **7.3 GiB** | ✅ Success | The default upstream experience. Heavy but feature-complete. |
| **Hyprland** | `sheng-hyprland` | **6.7 GiB** | ✅ Success | The lightest compositor available, saving over 600MB compared to GNOME. |
| **Niri** | `sheng-niri` | - | 🧪 Ready to test | Touch-oriented profile with Waybar, wvkbd, and Xwayland Satellite. |
| **KDE Plasma 6** | `sheng-plasma` | - | ⚠️ Failed | Linking `qtwebengine` may cause Out-Of-Memory (OOM) on 8GB devices. Binary cache is recommended. |
| **Phosh** | `sheng-phosh` | **7.6 GiB** | ✅ Success | Minimal touch interface, optimized for mobile devices. |

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
