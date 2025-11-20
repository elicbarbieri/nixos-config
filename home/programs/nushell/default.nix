{ pkgs }:

let
  # Import all config modules
  completions = import ./completions.nix { inherit pkgs; };
  initScripts = import ./init-scripts.nix { inherit pkgs; };
  envContent = import ./env.nix;
  configContent = import ./config.nix;
  keybindingsContent = import ./keybindings.nix;
  aliasesContent = import ./aliases.nix;
  promptContent = import ./prompt.nix;
  direnvContent = import ./direnv.nix;

  # Environment configuration (env.nu)
  envConfig = pkgs.writeText "env.nu" envContent;

  # Main configuration (config.nu)
  mainConfig = pkgs.writeText "config.nu" ''
    ${configContent}
    ${keybindingsContent}
    ${aliasesContent}
    ${promptContent}
    ${direnvContent}
    
    # Load init scripts (shell integrations)
    source ${initScripts.atuin}
    source ${initScripts.carapace}
    
    # Load completions
    source ${completions.uv}
    source ${completions.ruff}
  '';

in
pkgs.writeShellScriptBin "nu" ''
  exec ${pkgs.nushell}/bin/nu --env-config ${envConfig} --config ${mainConfig} "$@"
''
