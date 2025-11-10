# Enhanced Nushell Configuration

source ~/.config/nushell/scripts/atuin.nu

# Enable Vi mode for readline
$env.config.edit_mode = "vi"

$env.config.keybindings = [
    # Shift+Enter for newline (multiline commands)
    {
        name: insert_newline
        modifier: shift
        keycode: enter
        mode: [emacs, vi_insert]
        event: { edit: insertnewline }
    }
    
    # Enhanced completion menu
    {
        name: completion_menu
        modifier: none
        keycode: tab
        mode: [emacs, vi_insert]
        event: {
            until: [
                { send: menu name: completion_menu }
                { send: menunext }
            ]
        }
    }
    
    # Quick directory navigation with fzf
    {
        name: quick_cd
        modifier: control
        keycode: char_g
        mode: [emacs, vi_insert]
        event: {
            send: executehostcommand
            cmd: "cd (fd . -t d | fzf --height=50% --preview 'ls {}' | str trim)"
        }
    }
    
    # Open current directory in file manager
    {
        name: open_in_explorer
        modifier: control
        keycode: char_o
        mode: [emacs, vi_insert, vi_normal]
        event: {
            send: executehostcommand
            cmd: "xdg-open ."
        }
    }

    # Atuin Control + R search
    {
      name: atuin
      modifier: control
      keycode: char_r
      mode: [emacs, vi_normal, vi_insert]
      event: { send: executehostcommand cmd: (_atuin_search_cmd) }
    }
]

# Enhanced history configuration (modified for Atuin compatibility)
$env.config.history = {
    max_size: 100_000
    sync_on_enter: true
    file_format: "plaintext"  # Atuin will handle SQLite storage
    isolation: false
}

# Better table display
$env.config.table = {
    mode: "rounded"  # rounded, grid, compact, light, thin, with_love, reinforced, heavy, none
    index_mode: "always"  # always, never, auto
    show_empty: true
    padding: { left: 1, right: 1 }
    trim: {
        methodology: "wrapping"
        wrapping_try_keep_words: true
        truncating_suffix: "..."
    }
}

# Improved error handling and display
$env.config.error_style = "fancy"
$env.config.show_banner = false
$env.config.use_ansi_coloring = true
$env.config.bracketed_paste = true
$env.config.use_kitty_protocol = true

# Better datetime formatting
$env.config.datetime_format = {
    normal: "%a, %d %b %Y %H:%M:%S %z"
    table: "%m/%d/%y %I:%M:%S%p"
}

# Enhanced completions
$env.config.completions = {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "prefix"
    external: {
        enable: true
        max_results: 100
        completer: {|spans|
            carapace $spans.0 nushell ...$spans
            | from json
            | get -o value
        }
    }
    use_ls_colors: true
}

# Cursor shapes for vi mode
$env.config.cursor_shape = {
    emacs: line
    vi_insert: line
    vi_normal: block
}



# Development aliases
alias kgp = kubectl get pods
alias kgd = kubectl get deployments
alias d = docker
alias dc = docker compose
alias gs = git status
alias wt = git worktree

# Quick navigation
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..

# Utility functions
def l [dir?: path] {
    match $dir {
        null => (ls -la)
        _ => (ls -la $dir)
    } | select name type mode user size modified accessed 
}

# Load Scripts
source ~/.config/nushell/scripts/plugins.nu

# Load your existing keyboard manager script
alias kb = nu ~/.config/nushell/scripts/keyboard-manager.nu

# Load completions
source ~/.config/nushell/completions/ruff.nu  
source ~/.config/nushell/completions/ty.nu
source ~/.config/nushell/completions/uv.nu
use completions *

# Plugin configuration
$env.config.plugin_gc = {
    default: {
        enabled: true
        stop_after: 10sec
    }
    plugins: {}
}
