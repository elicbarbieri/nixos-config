{ pkgs }:

let
  starshipConfig = pkgs.writeText "starship.toml" ''
    # Left prompt: python/nix-shell indicator, custom repo name, directory path, character
    format = "$python$nix_shell''${custom.git_repo}$directory$character"

    # Right prompt: git branch, git status, ssh indicator, sudo indicator, shell level
    right_format = "$git_branch$git_status$hostname$sudo$shlvl"

    add_newline = false

    # Custom module to show actual repo name (works for both worktrees and main repos)
    [custom.git_repo]
    command = """
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || exit 1
if [ -f "$toplevel/.git" ]; then
  # Worktree: get parent dir name and strip .git suffix
  repo=$(basename $(dirname "$toplevel"))
  echo "''${repo%.git}"
else
  # Regular repo
  basename "$toplevel"
fi
"""
    shell = ["bash"]
    when = true
    format = "[$output]($style) "
    style = "bold #e4b7f3"

    # Nix shell indicator
    [nix_shell]
    symbol = "\\[nix-shell\\] "
    format = "[$symbol](bold #82d3e2)"
    heuristic = false

    # Directory - shows path within repo (custom module shows repo name)
    [directory]
    style = "bold #95d5a7"
    format = "[$path]($style)[$read_only]($read_only_style) "
    truncation_length = 3
    truncate_to_repo = true
    truncation_symbol = "…/"
    repo_root_style = "bold #95d5a7"
    repo_root_format = "[$path]($style)[$read_only]($read_only_style)"

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
    format = "[$symbol(venv)]($style) "
    style = "bold #c3d696"
    detect_extensions = []
    detect_files = []
    detect_folders = []
    pyenv_version_name = false
  '';

in
pkgs.writeShellScriptBin "starship" ''
  export STARSHIP_CONFIG=${starshipConfig}
  exec ${pkgs.starship}/bin/starship "$@"
''
