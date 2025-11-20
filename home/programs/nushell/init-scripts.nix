{ pkgs }:

let
  # Import atuin config for build-time init script generation
  atuinSettings = import ../atuin/settings.nix;
  atuinHistoryFilter = import ../atuin/history-filter.nix;
  
  # Minimal atuin config for init script generation
  atuinConfigToml = pkgs.writeText "atuin-config.toml" ''
    auto_sync = ${if atuinSettings.auto_sync then "true" else "false"}
    search_mode = "${atuinSettings.search_mode}"
  '';
  
in
# Auto-generate shell init scripts at build time
{
  # Atuin shell integration (history search with Ctrl+R only, up arrow disabled)
  atuin = pkgs.runCommand "atuin-init.nu" {
    buildInputs = [ pkgs.atuin ];
  } ''
    # Set up temporary home and config directories for build
    export HOME=$(mktemp -d)
    export ATUIN_CONFIG_DIR=$HOME/.config/atuin
    mkdir -p $ATUIN_CONFIG_DIR
    trap "rm -rf $HOME" EXIT
    
    # Link config file
    ln -s ${atuinConfigToml} $ATUIN_CONFIG_DIR/config.toml
    
    # Generate init script
    ${pkgs.atuin}/bin/atuin init nu --disable-up-arrow > $out
  '';
  
  # Carapace shell integration (external completer with alias expansion)
  carapace = pkgs.runCommand "carapace-init.nu" {} ''
    ${pkgs.carapace}/bin/carapace _carapace nushell > $out
  '';
}
