''
# Core settings
$env.config.show_banner = false
$env.config.buffer_editor = "nvim"

# NIX-LD Support (for running non-NixOS binaries)
if "NIX_LD_LIBRARY_PATH" in $env {
    $env.LD_LIBRARY_PATH = $env.NIX_LD_LIBRARY_PATH
}

# Path Configuration
$env.PATH = ($env.PATH | split row (char esep))
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.cargo/bin")
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin")
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.bun/bin")
''
