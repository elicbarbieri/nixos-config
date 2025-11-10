use std "path add"

# Nushell environment configuration
# Note: Nushell doesn't read bash session vars, so we manage PATH here
# Keep this in sync with home/default.nix sessionPath

# Environment Variables
$env.config.show_banner = false
$env.config.buffer_editor = "nvim"
$env.EDITOR = "nvim"

# NIX-LD Support (for running non-NixOS binaries like Python packages)
# NixOS sets NIX_LD_LIBRARY_PATH, we just need to expose it as LD_LIBRARY_PATH
# so that Python and other tools can find the dynamically linked libraries
if "NIX_LD_LIBRARY_PATH" in $env {
    $env.LD_LIBRARY_PATH = $env.NIX_LD_LIBRARY_PATH
}

# Path Configuration
# Add user-specific paths (keep in sync with home/default.nix)
$env.PATH = ($env.PATH | split row (char esep))
path add $"($env.HOME)/.cargo/bin"
path add $"($env.HOME)/.local/bin"
path add $"($env.HOME)/.bun/bin"
