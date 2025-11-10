{ config, pkgs, lib, ... }:

let
  # Generate completions at build time
  uvCompletion = pkgs.runCommand "uv-completion.nu" {} ''
    ${pkgs.uv}/bin/uv generate-shell-completion nushell > $out
  '';
  
  # Ruff doesn't have built-in completion generation, but we can try
  # Note: If ruff doesn't support it, we'll need to use the static file
  # For now, keeping the static completion from dotfiles
  
in {
  programs.nushell = {
    enable = true;
    
    extraEnv = ''
      # Environment Variables
      $env.config.show_banner = false
      $env.config.buffer_editor = "nvim"
      $env.EDITOR = "nvim"

      # NIX-LD Support (for running non-NixOS binaries)
      if "NIX_LD_LIBRARY_PATH" in $env {
          $env.LD_LIBRARY_PATH = $env.NIX_LD_LIBRARY_PATH
      }

      # Path Configuration
      $env.PATH = ($env.PATH | split row (char esep))
      $env.PATH = ($env.PATH | prepend $"($env.HOME)/.cargo/bin")
      $env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin")
      $env.PATH = ($env.PATH | prepend $"($env.HOME)/.bun/bin")
    '';
    
    extraConfig = ''
      # Atuin integration
      def _atuin_search_cmd [] {
        if (which atuin | is-empty) {
          return "echo 'Atuin not found'"
        }
        $"atuin search --cmd-only --limit 1 (commandline | str trim | str replace --all --regex '^\\s*' '''')"
      }

      # Enable Vi mode
      $env.config.edit_mode = "vi"

      $env.config.keybindings = [
          # Shift+Enter for newline
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

      # Completions
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

      # Cursor shapes
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

      # Keyboard manager alias
      alias kb = nu ~/.config/nushell/scripts/keyboard-manager.nu
      
      # Load auto-generated completions
      source ${uvCompletion}
    '';
  };
  
  # Keep scripts that are dynamically loaded
  home.file.".config/nushell/scripts/keyboard-manager.nu".source = ../../dotfiles/nushell/scripts/keyboard-manager.nu;
  
  # Keep static completions that can't be auto-generated
  home.file.".config/nushell/completions/ruff.nu".source = ../../dotfiles/nushell/completions/ruff.nu;
  home.file.".config/nushell/completions/ty.nu".source = ../../dotfiles/nushell/completions/ty.nu;
}
