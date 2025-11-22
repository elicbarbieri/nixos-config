# NixOS Configuration

Flake-based NixOS configuration with modular design, Hyprland desktop environment, and Ax-Shell integration.

## Structure

```
├── flake.nix                    # Main flake configuration
├── hosts/
│   └── elicb-xps/               # set to hostname of machine
│       ├── default.nix          # Host-specific settings & Nvidia config
│       ├── disko-config.nix     # Disk partitioning configuration
│       └── hardware-configuration.nix
├── home/
│   ├── default.nix              # Home-manager configuration (dotfile management)
│   ├── programs/                # Wrapped core programs with config included
│   └── shell.nix                # Shell environment setup
├── modules/
│   ├── common.nix               # Shared settings across all hosts
│   ├── desktop/                 # Desktop environment (Hyprland + Ax-Shell)
│   ├── performance/             # System performance and maintenance
│   └── vm-variant.nix           # VM build configuration for nixos-rebuild build-vm and nix build .#nixosConfigurations.<hostname>.config.system.build.vm
├── specializations/
│   ├── gaming.nix               # Gaming optimizations & programs (NVIDIA sync + TLP)
│   └── low-power.nix            # Battery saving mode (offload + TLP)
├── dotfiles/                    # User dotfile dirs (symlinked by home-manager)  -- Everything here updates in realtime without a rebuild-switch
│   ├── hypr/                    # Hyprland config (keybinds, autostart, animations, etc.)
│   ...
├── assets/
│   └── wallpapers/              # Desktop wallpapers
└── ax-shell-module/             # Custom Ax-Shell flake module
    ├── nix/
    │   ├── modules/             # NixOS module definitions
    │   └── packages/            # Custom package derivations
    └── flake.nix
```

## Building and Switching

### Physical System

```bash
# Build and switch to main configuration
sudo nixos-rebuild switch --flake .#elicb-xps

# Build with a specialization
sudo nixos-rebuild switch --flake .#elicb-xps --specialisation gaming
sudo nixos-rebuild switch --flake .#elicb-xps --specialisation low-power

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

## System Setup

- ax-shell wallpapers are a little finicky.  Go to top dock -> Wallpapers -> Click on Wallpaper to set & create CSS colors for everything
- GPG agent will auto-add the GPG key in .gnupg/  To add SSH keys, `ssh-add ~/.ssh/id_rsa` and then the ssh key will be prompted via rofi popup
- I have non-nix packages as first class-citizens, so `uv tool install` `bun add -g` `cargo install` will all work for quickly installing utilities

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
