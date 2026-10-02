{ pkgs, starship }:

let
  # Import all config modules
  completions = import ./completions.nix { inherit pkgs; };
  initScripts = import ./init-scripts.nix { inherit pkgs starship; };
  envContent = import ./env.nix;
  configContent = import ./config.nix;
  keybindingsContent = import ./keybindings.nix;
  aliasesContent = import ./aliases.nix;
  direnvContent = import ./direnv.nix;

  # Environment configuration (env.nu)
  envConfig = pkgs.writeText "env.nu" envContent;

  # Main configuration (config.nu)
  mainConfig = pkgs.writeText "config.nu" ''
    ${configContent}
    ${keybindingsContent}
    ${aliasesContent}
    ${direnvContent}
    
    # Load init scripts (shell integrations)
    source ${initScripts.atuin}
    source ${initScripts.carapace}

    # carapace knows nothing → explicit fish bridge (zstd, zellij, psql, … ~1000 cmds)
    # - CARAPACE_BRIDGES=fish can't discover fish 4's embedded completions (no .fish files on disk)
    let carapace_only = $env.config.completions.external.completer
    $env.config.completions.external.completer = {|spans|
      let found = do $carapace_only $spans
      if ($found | is-not-empty) { return $found }
      ^carapace $"($spans.0)/fish" nushell ...$spans | from json
    }
    source ${initScripts.starship}
    source ${initScripts.nixYourShell}
    
    # Load completions
    source ${completions.uv}
    source ${completions.ruff}
  '';

in
pkgs.writeShellScriptBin "nu" ''
  # Build command with conditional config injection
  cmd="${pkgs.nushell}/bin/nu"
  
  # Only add --env-config if not already specified
  if [[ ! " $* " =~ " --env-config " ]]; then
    cmd="$cmd --env-config ${envConfig}"
  fi
  
  # Only add --config if not already specified
  if [[ ! " $* " =~ " --config " ]]; then
    cmd="$cmd --config ${mainConfig}"
  fi
  
  exec $cmd "$@"
''
