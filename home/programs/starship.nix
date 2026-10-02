{ pkgs }:

let
  ansi = builtins.elemAt (import ./palette.nix).ansi;

  starshipConfig = pkgs.writeText "starship.toml" ''
    format = "$python$nix_shell$directory$character"
    right_format = "$git_branch$git_status$hostname$sudo$shlvl"
    add_newline = false

    [nix_shell]
    symbol = "\\[nix-shell\\] "
    format = "[$symbol](bold ${ansi 6})"

    # in a repo: worktree dir name leads (repo-name-2/src), no before-root `…/`
    [directory]
    style = "bold ${ansi 2}"
    repo_root_style = "bold ${ansi 5}"
    repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) "
    truncation_length = 5
    truncation_symbol = "…/"

    [git_branch]
    symbol = " "
    format = "[$symbol$branch]($style) "
    style = "bold ${ansi 3}"

    [git_status]
    format = "([$all_status$ahead_behind]($style))"
    style = "bold ${ansi 3}"
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

    [hostname]
    ssh_only = true
    format = "[ssh](bold ${ansi 4}) "
    disabled = false

    [sudo]
    format = "[sudo](bold ${ansi 1}) "
    disabled = false

    [shlvl]
    threshold = 2
    format = "[↕$shlvl](bold ${ansi 14}) "
    disabled = false

    # active venv only (no detection by files)
    [python]
    symbol = " "
    format = "[$symbol(venv)]($style) "
    style = "bold ${ansi 11}"
    detect_extensions = []
    detect_files = []
    detect_folders = []
    pyenv_version_name = false
  '';

in
pkgs.writeShellScriptBin "starship" ''
  export STARSHIP_CONFIG="''${STARSHIP_CONFIG:-${starshipConfig}}"
  exec ${pkgs.starship}/bin/starship "$@"
''
