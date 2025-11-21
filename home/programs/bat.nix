{ pkgs }:

let
  # Bat configuration
  batConfigFile = pkgs.writeText "bat-config" ''
    --theme="Catppuccin Mocha"
    --style=header-filename,changes
    --paging=auto
    --decorations=always
    --wrap=auto
    --tabs=4

    # Syntax Mappings
    --map-syntax="*.conf:INI"

    # Environment files as bash
    --map-syntax=".env:Bash"
    --map-syntax=".envrc:Bash"

    # Log files
    --map-syntax="*.log:Log"
  '';

in
pkgs.writeShellScriptBin "bat" ''
  export BAT_CONFIG_PATH=${batConfigFile}
  exec ${pkgs.bat}/bin/bat "$@"
''
