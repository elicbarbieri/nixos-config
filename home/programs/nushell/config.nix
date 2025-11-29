''
# Edit mode (emacs for better Starship compatibility)
$env.config.edit_mode = "emacs"
$env.config.buffer_editor = "nvim"

# History configuration
$env.config.history = {
    max_size: 100_000
    sync_on_enter: true
    file_format: "plaintext"
    isolation: false
}

# Table display
$env.config.table = {
    mode: "rounded"
    index_mode: "never"
    show_empty: true
    padding: { left: 1, right: 1 }
    trim: {
        methodology: "wrapping"
        wrapping_try_keep_words: true
        truncating_suffix: "..."
    }
}

# Error handling and display
$env.config.error_style = "fancy"
$env.config.show_banner = false
$env.config.use_ansi_coloring = true
$env.config.bracketed_paste = true
$env.config.use_kitty_protocol = true

# Datetime formatting
$env.config.datetime_format = {
    normal: "%a, %d %b %Y %H:%M:%S %z"
    table: "%m/%d/%y %I:%M:%S%p"
}

# Completions (carapace init script will configure external completer)
$env.config.completions = {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "prefix"
    use_ls_colors: true
}

# Cursor shape
$env.config.cursor_shape = {
    emacs: line
}

# Plugin configuration
$env.config.plugin_gc = {
    default: {
        enabled: true
        stop_after: 10sec
    }
    plugins: {}
}
''
