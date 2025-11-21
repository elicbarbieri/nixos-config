{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.05";
  
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
  ];
  
  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";  # Silence direnv's verbose export messages
  };

  programs.direnv = {
    enable = true;
    enableNushellIntegration = false;  # We handle this manually in nushell config
    nix-direnv.enable = true;  # Better Nix integration with caching
    
    config = {
      # Suppress loading/unloading messages
      hide_env_diff = true;
    };
  };
  
}
