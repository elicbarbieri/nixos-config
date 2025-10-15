use std "path add"

# Nushell environment configuration
# Note: Nushell doesn't read bash session vars, so we manage PATH here
# Keep this in sync with home/default.nix sessionPath

# Environment Variables
$env.config.show_banner = false
$env.config.buffer_editor = "nvim"
$env.EDITOR = "nvim"
$env.PAGER = "bat"
$env.MANPAGER = "bat"

# Path Configuration
# Add user-specific paths (keep in sync with home/default.nix)
$env.PATH = ($env.PATH | split row (char esep))
path add $"($env.HOME)/.cargo/bin"
path add $"($env.HOME)/.local/bin"
path add $"($env.HOME)/.bun/bin"
