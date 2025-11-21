{ pkgs }:

let
  gitconfigFile = pkgs.writeText "gitconfig" ''
    [user]
      name = Eli Barbieri
      email = elicbarbieri@gmail.com
      signingkey = FC47C35DCE0A045C
    [init]
      defaultBranch = master
    [commit]
      gpgsign = true
    [pull]
      rebase = true
    [core]
      excludesfile = ${pkgs.writeText "gitignore" ''
        **/.claude/settings.local.json
        *.qcow2
        .direnv/
      ''}
  '';
in
pkgs.writeShellScriptBin "git" ''
  export GIT_CONFIG_GLOBAL=${gitconfigFile}
  exec ${pkgs.git}/bin/git "$@"
''
