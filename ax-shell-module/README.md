# Ax-Shell NixOS Module

## 🚀 Quick Start

### Using Flakes (Recommended)

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    ax-shell.url = "github:axenide/ax-shell";
  };
  
  outputs = { nixpkgs, hyprland, ax-shell, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ax-shell.nixosModules.default
        {
          programs.hyprland = {
            enable = true;
          };

          programs.ax-shell = {
            enable = true;
            terminalCommand = "kitty -e";
            colors.primary = "#0066cc";
          };
        }
      ];
    };
  };
}
```

### Without Flakes

Add to your `configuration.nix`:

```nix
{ pkgs, ... }: {
  imports = [
    (builtins.fetchTarball {
      url = "https://github.com/axenide/ax-shell/archive/main.tar.gz";
    }) + "/nix/modules/ax-shell.nix"
  ];
  
  programs.ax-shell = {
    enable = true;
    terminalCommand = "alacritty -e";
  };
}
```

## 🎨 Configuration Examples

### Basic Setup

```nix
{
  programs.ax-shell = {
    enable = true;
    user = "myuser";
    terminalCommand = "kitty -e";
    wallpapersDir = "~/Pictures/wallpapers";
    
    keybinds = {
      mode = "declarative";  # or "imperative" or "disabled"
      launcher = "SUPER, SPACE";
      dashboard = "SUPER, D";
      overview = "SUPER, TAB";
      power = "SUPER, ESCAPE";
    };
  };
}
```

## ⌨️ Keybind Management

Ax-Shell supports two approaches for managing Hyprland keybinds:

### Option 1: Manual Configuration (Recommended)

**Best for:** Users who manage dotfiles in git, want hot-reloadable keybinds, or prefer full control.

**Setup:**
1. Set `keybinds.mode = "disabled"` (or omit the keybinds section entirely)
2. Copy keybinds from the [Keybind Reference](#keybind-reference-for-manual-configuration) section below into your Hyprland config
3. Edit keybinds directly in your dotfiles
4. Reload with `hyprctl reload` - **no NixOS rebuild needed!**

```nix
{
  programs.ax-shell = {
    enable = true;
    user = "myuser";
    # keybinds.mode = "disabled" is the default - module does nothing
  };
}
```

### Option 2: Declarative Mode (NixOS-Managed)

**Best for:** Pure NixOS setups, reproducible configurations, users who don't mind rebuilding to change keybinds.

**Requirements:**
- Must have `wayland.windowManager.hyprland.enable = true` in home-manager

```nix
{
  # Enable home-manager hyprland config
  home-manager.users.myuser = {
    wayland.windowManager.hyprland.enable = true;
  };

  programs.ax-shell = {
    enable = true;
    user = "myuser";
    
    keybinds = {
      mode = "declarative";
      
      # Core keybinds (all optional, set to null to disable)
      restart = "SUPER ALT, B";
      launcher = "SUPER, R";
      dashboard = "SUPER, D";
      overview = "SUPER, TAB";
      power = "SUPER, ESCAPE";
      toolbox = "SUPER, S";
      
      # Optional widgets (null by default)
      pins = "SUPER, Q";
      kanban = "SUPER, N";
      tmux = "SUPER, T";
      wallpapers = "SUPER, COMMA";
      randomWallpaper = "SUPER SHIFT, COMMA";
      audioMixer = "SUPER, M";
      emojiPicker = "SUPER, PERIOD";
      clipboardHistory = "SUPER, V";
      bluetooth = null;  # Disabled
      
      # Advanced controls
      toggleBar = "SUPER CTRL, B";
      toggleCaffeine = "SUPER SHIFT, M";
      reloadCss = "SUPER SHIFT, B";
    };
  };
}
```

### Available Keybinds

| Option | Default | Description |
|--------|---------|-------------|
| `restart` | `SUPER ALT, B` | Restart ax-shell |
| `launcher` | `SUPER, R` | Application launcher |
| `dashboard` | `SUPER, D` | Dashboard widgets |
| `overview` | `SUPER, TAB` | Workspace overview |
| `power` | `SUPER, ESCAPE` | Power menu |
| `toolbox` | `SUPER, S` | Quick tools |
| `pins` | `null` | Pins/bookmarks |
| `kanban` | `null` | Kanban board |
| `tmux` | `null` | Tmux selector |
| `wallpapers` | `null` | Wallpaper picker |
| `randomWallpaper` | `null` | Set random wallpaper |
| `audioMixer` | `null` | Volume mixer |
| `emojiPicker` | `null` | Emoji picker |
| `clipboardHistory` | `null` | Clipboard manager |
| `bluetooth` | `null` | Bluetooth manager |
| `toggleBar` | `null` | Toggle bar visibility |
| `toggleCaffeine` | `null` | Toggle auto-sleep inhibitor |
| `reloadCss` | `null` | Reload CSS styles |

**Note:** Set any keybind to `null` to disable it in declarative mode.

### Module Structure

```
nix/
├── modules/
│   ├── ax-shell.nix          # Main module with comprehensive options
│   ├── lib.nix              # Utility functions and config generation
│   └── wayland-session.nix  # Wayland session integration
└── packages/
    ├── ax-shell.nix          # Main package definition
    ├── fabric-cli.nix        # Fabric framework dependency
    ├── python-fabric.nix     # Fabric framework dependency
    ├── gray.nix              # System tray library
    └── zed-fonts.nix         # Font package
```

## 🔧 Configuration Options

### Core Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable Ax-Shell |
| `package` | package | `pkgs.ax-shell` | Package to use |
| `terminalCommand` | string | `"kitty -e"` | Terminal launcher |
| `wallpapersDir` | string | `~/.config/Ax-Shell/assets/wallpapers_example` | Wallpaper directory |
| `xwayland.enable` | bool | `true` | XWayland support |
| `session.enable` | bool | `true` | Display manager integration |
| `fonts.enable` | bool | `true` | Install recommended fonts |

### Theming Options

Full color customization with hex codes:

- `colors.primary`, `colors.secondary`, `colors.tertiary` - Accent colors
- `colors.foreground`, `colors.background` - Base interface colors
- `colors.surface`, `colors.surfaceBright` - Panel backgrounds
- `colors.red`, `colors.green`, `colors.blue`, etc. - Status colors

---

## 📋 Keybind Reference (For Manual Configuration)

If you're using manual keybind management (`keybinds.mode = "disabled"`), copy the configuration below into your Hyprland config file.

### Complete Keybind Configuration

```conf
# =============================================================================
# Ax-Shell Keybinds
# =============================================================================

# Clipboard history daemon (required for cliphist widget)
exec-once = wl-paste --type image --watch cliphist store

# Ax-Shell helper variable
$fabricSend = fabric-cli exec ax-shell

# -----------------------------------------------------------------------------
# Core Functions
# -----------------------------------------------------------------------------

bind = SUPER ALT, B, exec, killall ax-shell; uwsm-app $(python $HOME/.config/Ax-Shell/main.py) # Restart Ax-Shell
bind = SUPER, R, exec, $fabricSend 'notch.open_notch("launcher")' # App Launcher
bind = SUPER, D, exec, $fabricSend 'notch.open_notch("dashboard")' # Dashboard
bind = SUPER, TAB, exec, $fabricSend 'notch.open_notch("overview")' # Overview
bind = SUPER, ESCAPE, exec, $fabricSend 'notch.open_notch("power")' # Power Menu

# -----------------------------------------------------------------------------
# Optional Widgets (uncomment to enable)
# -----------------------------------------------------------------------------

bind = SUPER, S, exec, $fabricSend 'notch.open_notch("tools")' # Toolbox
# bind = SUPER, Q, exec, $fabricSend 'notch.open_notch("pins")' # Pins
# bind = SUPER, N, exec, $fabricSend 'notch.open_notch("kanban")' # Kanban Board
# bind = SUPER, T, exec, $fabricSend 'notch.open_notch("tmux")' # Tmux Selector
# bind = SUPER, COMMA, exec, $fabricSend 'notch.open_notch("wallpapers")' # Wallpaper Picker
# bind = SUPER SHIFT, COMMA, exec, $fabricSend 'notch.dashboard.wallpapers.set_random_wallpaper(None, external=True)' # Random Wallpaper
# bind = SUPER, M, exec, $fabricSend 'notch.open_notch("mixer")' # Audio Mixer
# bind = SUPER, PERIOD, exec, $fabricSend 'notch.open_notch("emoji")' # Emoji Picker
# bind = SUPER, V, exec, $fabricSend 'notch.open_notch("cliphist")' # Clipboard History
# bind = SUPER, B, exec, $fabricSend 'notch.open_notch("bluetooth")' # Bluetooth Manager

# -----------------------------------------------------------------------------
# Advanced Controls (uncomment to enable)
# -----------------------------------------------------------------------------

# bind = SUPER CTRL, B, exec, $fabricSend 'from utils.global_keybinds import get_global_keybind_handler; get_global_keybind_handler().toggle_bar()' # Toggle Bar Visibility
# bind = SUPER SHIFT, M, exec, $fabricSend 'notch.dashboard.widgets.buttons.caffeine_button.toggle_inhibit(external=True)' # Toggle Caffeine (Disable Auto-Sleep)
# bind = SUPER SHIFT, B, exec, $fabricSend 'app.set_css()' # Reload CSS Styles
```

### Usage Instructions

1. **Copy the configuration above** into your Hyprland config (typically `~/.config/hypr/hyprland.conf` or a sourced file)

2. **Reload Hyprland** to apply changes:
   ```bash
   hyprctl reload
   ```

3. **Customize** by editing keybinds directly in your config file

4. **Uncomment** optional widgets you want to use

### Keybind Table

| Keybind | Default | Description |
|---------|---------|-------------|
| **Core Functions** | | |
| Restart | `SUPER ALT B` | Restart Ax-Shell |
| Launcher | `SUPER R` | Application launcher |
| Dashboard | `SUPER D` | Dashboard widgets |
| Overview | `SUPER TAB` | Workspace overview |
| Power | `SUPER ESCAPE` | Power menu |
| **Optional Widgets** | | |
| Toolbox | `SUPER S` | Quick tools |
| Pins | `SUPER Q` | Pinned items/bookmarks |
| Kanban | `SUPER N` | Kanban board |
| Tmux | `SUPER T` | Tmux session selector |
| Wallpapers | `SUPER COMMA` | Wallpaper picker |
| Random Wallpaper | `SUPER SHIFT COMMA` | Set random wallpaper |
| Audio Mixer | `SUPER M` | Volume mixer |
| Emoji Picker | `SUPER PERIOD` | Emoji picker |
| Clipboard History | `SUPER V` | Clipboard manager |
| Bluetooth | `SUPER B` | Bluetooth manager |
| **Advanced** | | |
| Toggle Bar | `SUPER CTRL B` | Toggle bar visibility |
| Toggle Caffeine | `SUPER SHIFT M` | Toggle auto-sleep inhibitor |
| Reload CSS | `SUPER SHIFT B` | Reload CSS styles |

### Customization Tips

**Modifier Keys:**
- `SUPER` - Usually the Windows/Command key
- `ALT` - Alt key
- `SHIFT` - Shift key
- `CTRL` - Control key

**Combining Modifiers:**
```conf
bind = SUPER SHIFT ALT, KEY, exec, command
```

**Hot Reload:**
All changes to keybinds take effect immediately with `hyprctl reload` - no NixOS rebuild required!

### Troubleshooting

**Keybind not working?**
1. Check for conflicts: `hyprctl binds`
2. Verify Ax-Shell is running: `pgrep ax-shell`
3. Test fabric-cli: `fabric-cli exec ax-shell 'print("test")'`
4. Check Hyprland logs: `hyprctl logs`

**Widget not opening?**
- Some widgets may require additional packages (e.g., `tmux` for tmux selector)
- Verify the widget is available in your Ax-Shell installation

**Clipboard history not working?**
- Ensure `cliphist` package is installed
- Verify the `exec-once` daemon is running: `pgrep wl-paste`

