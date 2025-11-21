{ pkgs }:

let
  starshipConfig = pkgs.writeText "starship.toml" ''
    # Left prompt: python/nix-shell indicator, directory, character
    format = "$python$nix_shell$directory$character"
    
    # Right prompt: git info, ssh indicator, sudo indicator, shell level
    right_format = "$git_branch$git_status$hostname$sudo$shlvl"
    
    add_newline = false

    # Character changes based on success/error
    [character]
    success_symbol = "[>](bold #95d5a7)"
    error_symbol = "[>](bold #ffb2b9)"
    format = "$symbol "

    # Nix shell indicator (only show when actually in nix-shell/nix develop)
    [nix_shell]
    symbol = "\\[nix-shell\\] "
    format = "[$symbol](bold #82d3e2)"
    heuristic = false

    # Directory
    [directory]
    style = "bold #95d5a7"
    format = "[$path]($style)[$read_only]($read_only_style) "
    truncation_length = 3
    truncate_to_repo = true
    truncation_symbol = "…/"
    repo_root_style = "bold #e4b7f3"
    repo_root_format = "[$repo_root]($repo_root_style) [$path]($style)[$read_only]($read_only_style) "

    # Git branch
    [git_branch]
    symbol = " "
    format = "[$symbol$branch]($style) "
    style = "bold #b8cf84"

    # Git status - simplified with counts
    [git_status]
    format = "([$all_status$ahead_behind]($style))"
    style = "bold #b8cf84"
    conflicted = "="
    ahead = "⇡''${count}"
    behind = "⇣''${count}"
    diverged = "⇕''${ahead_count}⇣''${behind_count}"
    up_to_date = ""
    untracked = "?''${count}"
    stashed = ""
    modified = "!''${count}"
    staged = "+''${count}"
    renamed = "»''${count}"
    deleted = "✘''${count}"

    # SSH indicator
    [hostname]
    ssh_only = true
    format = "[ssh](bold #adc6ff) "
    disabled = false

    # Sudo credential cache indicator
    [sudo]
    format = "[sudo](bold #ffb2b9) "
    disabled = false

    # Shell level (when nested)
    [shlvl]
    threshold = 2
    format = "[↕$shlvl](bold #97dae7) "
    disabled = false

    # Python virtual environment (only show when active)
    [python]
    symbol = " "
    format = "[$symbol($virtualenv)]($style) "
    style = "bold #c3d696"
    detect_extensions = []
    detect_files = []
    detect_folders = []
    pyenv_version_name = false

    # Disable all other language version modules
    [nodejs]
    disabled = true
    
    [rust]
    disabled = true
    
    [golang]
    disabled = true
    
    [java]
    disabled = true
    
    [ruby]
    disabled = true
    
    [php]
    disabled = true
    
    [lua]
    disabled = true
    
    [package]
    disabled = true
    
    [terraform]
    disabled = true
    
    [kubernetes]
    disabled = true
    
    [docker_context]
    disabled = true
    
    [aws]
    disabled = true
    
    [gcloud]
    disabled = true
    
    [azure]
    disabled = true
  '';

in
pkgs.writeShellScriptBin "starship" ''
  export STARSHIP_CONFIG=${starshipConfig}
  exec ${pkgs.starship}/bin/starship "$@"
''
