# NixOS Configuration

Flake-based NixOS configuration with modular design, Hyprland desktop environment, and Ax-Shell integration.

## Structure

```
├── flake.nix                    # Main flake configuration
├── hosts/
│   └── elicb-xps/               # Dell XPS 17 9730 configuration
│       ├── default.nix          # Host-specific settings
│       └── hardware-configuration.nix
├── home/
│   └── default.nix              # Home-manager configuration (dotfile management)
├── modules/
│   ├── common.nix               # Shared settings across all hosts
│   ├── desktop/                 # Desktop environment (Hyprland + Ax-Shell)
│   ├── performance/             # System performance and maintenance
│   └── vm-variant.nix           # Generic VM build configuration
├── specializations/
│   ├── performance-dev.nix      # Performance development mode
│   ├── gaming.nix               # Gaming optimizations (NVIDIA sync + TLP)
│   └── low-power.nix            # Battery saving mode (offload + TLP)
└── dotfiles/                    # User dotfiles (symlinked by home-manager)
```

## Building and Switching

### Physical System

```bash
# Build and switch to main configuration
sudo nixos-rebuild switch --flake .#elicb-xps

# Build with a specialization
sudo nixos-rebuild switch --flake .#elicb-xps --specialisation gaming
sudo nixos-rebuild switch --flake .#elicb-xps --specialisation low-power
sudo nixos-rebuild switch --flake .#elicb-xps --specialisation performance-dev

# Test in VM (applies to any host configuration)
nixos-rebuild build-vm --flake .#elicb-xps
./result/bin/run-elicb-xps-vm
```

### VM Testing

The `vm-variant.nix` module provides generic VM settings that apply to all hosts. Simply run:

```bash
nixos-rebuild build-vm --flake .#elicb-xps
./result/bin/run-elicb-xps-vm
```

VM features:
- Writable filesystem with tmpfs overlay
- 4GB RAM, 4 cores, 10GB disk
- Shared nixos-config directory
- Auto-login enabled
- Docker disabled by default
- Proper keyboard handling (Super key works)

## Features

### Core System
- **Flake-based**: Reproducible builds with locked dependencies
- **Modular design**: Clean separation of concerns
- **Performance optimized**: Zen kernel, ZRAM, auto-optimization
- **VM-ready**: Any host can be tested as a VM
- **Home-manager**: Declarative dotfile management with automatic symlinks

### Desktop Environment
- **Hyprland**: Modern Wayland compositor
- **Ax-Shell**: Python-based desktop shell with custom widgets
- **Wayland-native**: Proper XDG portal integration
- **Hardware acceleration**: Intel + NVIDIA hybrid graphics

### Dotfile Management
- **Home-manager integration**: All dotfiles automatically symlinked from `dotfiles/` to `~/.config/`
- **Live editing**: Edit dotfiles in the repo, changes appear immediately
- **Reproducible**: VMs and fresh installs get exact dotfile state
- **Declarative**: Dotfile locations defined in `home/default.nix`

### Power Management
- **NVIDIA Prime**: Configurable offload/sync modes
- **TLP**: Advanced power management in specializations
- **Default mode**: Offload (battery-optimized)
- **Gaming mode**: Sync (performance-optimized)
- **Low-power mode**: Aggressive power saving

### Specializations
Choose your workflow with boot-time specializations:

- **performance-dev**: High performance with elevated inotify limits
- **gaming**: Maximum performance, NVIDIA sync mode, TLP performance profile
- **low-power**: Battery optimization, offload mode, TLP powersave profile

## Shell Setup

- **Terminal**: Kitty with GPU acceleration
- **Shell**: Nushell with modern completions
- **History**: Atuin for command history sync
- **Prompt**: Custom with Carapace completions

## Package Management

### System Packages
Managed through `modules/common.nix` and `environment.systemPackages`

### Development Tools
- UV for Python project management
- Cargo for Rust
- Nix-ld for dynamic library compatibility

### User Tools
```bash
# Python tools
uv tool install <package>

# Rust tools
cargo install <package>
```

## Managing Dotfiles

Dotfiles are managed by home-manager and automatically symlinked from `dotfiles/` to `~/.config/`.

### How It Works

```bash
# Your dotfiles live in the repo:
~/nixos-config/dotfiles/hypr/hyprland.conf

# After rebuild, home-manager creates symlinks:
~/.config/hypr → /nix/store/.../home-manager-files/.config/hypr → ../dotfiles/hypr

# Edit directly in the repo:
vim ~/nixos-config/dotfiles/hypr/hyprland.conf
# Changes appear immediately in ~/.config/hypr

# Commit when you're happy:
git add dotfiles/hypr/hyprland.conf
git commit -m "Update Hyprland config"
```

### Adding New Dotfiles

Edit `home/default.nix`:
```nix
home.file = {
  ".config/your-app".source = ../dotfiles/your-app;
};
```

### Dotfiles Included

- **Hyprland**: Window manager configuration
- **Kitty**: Terminal emulator
- **Nushell**: Shell configuration and scripts
- **Neovim**: Editor setup with LazyVim
- **Git**: Global git config and ignore patterns
- **Ax-Shell**: Desktop shell customization
- And more: atuin, btop, lazygit, matugen, ruff

## Adding New Hosts

1. Create host directory: `hosts/your-hostname/`
2. Add `hardware-configuration.nix` (generate with `nixos-generate-config`)
3. Create `default.nix` with host-specific settings
4. Add to `flake.nix`:
   ```nix
   your-hostname = nixpkgs.lib.nixosSystem {
     system = "x86_64-linux";
     modules = [
       ./hosts/your-hostname
       ./modules/common.nix
       ./modules/desktop
       ./modules/performance
       ./modules/vm-variant.nix
       hyprland.nixosModules.default
       ax-shell.nixosModules.default
       
       home-manager.nixosModules.home-manager
       {
         home-manager.useGlobalPkgs = true;
         home-manager.useUserPackages = true;
         home-manager.users.yourusername = import ./home;
       }
     ];
     specialArgs = { inherit hyprland self ax-shell; };
   };
   ```

## Hardware Notes

### Dell XPS 17 9730
- Intel Core i9 + NVIDIA RTX 4070
- Hybrid graphics with Prime
- Thunderbolt 4 support
- BTRFS with compression
- Low-latency audio configuration
