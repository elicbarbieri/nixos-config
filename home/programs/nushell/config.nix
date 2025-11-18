{ ... }:

{
  # All the $env.config settings
  shellConfig = ''
    # Vi mode
    $env.config.edit_mode = "vi"
    
    # History configuration (atuin integration handles the hooks)
    $env.config.history = {
        max_size: 100_000
        sync_on_enter: true
        file_format: "plaintext"
        isolation: false
    }
    
    # Table display
    $env.config.table = {
        mode: "rounded"
        index_mode: "always"
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
    
    # Completions (carapace as external completer)
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
    
    # Plugin configuration
    $env.config.plugin_gc = {
        default: {
            enabled: true
            stop_after: 10sec
        }
        plugins: {}
    }
  '';
}
