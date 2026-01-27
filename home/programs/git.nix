{ pkgs }:

let
  gitconfigFile = pkgs.writeText "gitconfig" ''
    [user]
      name = Eli Barbieri
      email = elicbarbieri@gmail.com
      signingkey = ~/.ssh/id_ed25519.pub
    [gpg]
      format = ssh
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
