use std "path add"

# Nushell config
$env.config.show_banner = false
$env.config.buffer_editor = "nvim"
$env.EDITOR = "nvim"
$env.PAGER = "bat"
$env.MANPAGER = "bat"

# Path Config - NixOS handles all paths automatically
# Only add user-specific paths that aren't managed by NixOS
$env.PATH = ($env.PATH | split row (char esep))
path add $"($env.HOME)/.local/bin"

# Environment Variables - NixOS handles JAVA_HOME automatically
# Removed hardcoded Ubuntu Java path

# Auto-completion setup handled by NixOS package management
