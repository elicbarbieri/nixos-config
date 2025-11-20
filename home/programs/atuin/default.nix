{ pkgs }:

let
  # Import config modules
  settings = import ./settings.nix;
  historyFilter = import ./history-filter.nix;

  # Convert Nix settings to TOML format
  settingsToToml = settings: 
    let
      boolToString = b: if b then "true" else "false";
      listToToml = l: "[" + (builtins.concatStringsSep ", " (map (x: ''"${x}"'') l)) + "]";
    in ''
      # Sync settings
      auto_sync = ${boolToString settings.auto_sync}
      sync_frequency = "${settings.sync_frequency}"
      
      # Search settings
      search_mode = "${settings.search_mode}"
      filter_mode = "${settings.filter_mode}"
      
      # Display settings
      style = "${settings.style}"
      inline_height = ${toString settings.inline_height}
      show_preview = ${boolToString settings.show_preview}
      max_preview_height = ${toString settings.max_preview_height}
      show_help = ${boolToString settings.show_help}
      
      # Behavior settings
      exit_mode = "${settings.exit_mode}"
      keymap_mode = "${settings.keymap_mode}"
      
      # Workspace support
      workspaces = ${boolToString settings.workspaces}
      
      # History filter
      history_filter = ${listToToml historyFilter}
      
      # Common prefixes and subcommands
      common_prefix = ${listToToml settings.common_prefix}
      common_subcommands = ${listToToml settings.common_subcommands}
    '';

  # Generate config.toml
  configFile = pkgs.writeText "atuin-config.toml" (settingsToToml settings);

in
pkgs.writeShellScriptBin "atuin" ''
  export ATUIN_CONFIG_DIR=$(mktemp -d)
  trap "rm -rf $ATUIN_CONFIG_DIR" EXIT
  
  ln -s ${configFile} $ATUIN_CONFIG_DIR/config.toml
  
  exec ${pkgs.atuin}/bin/atuin "$@"
''
