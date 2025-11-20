{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.05";
  
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.bun/bin"
  ];
  

  programs.direnv = {
    enable = true;
    enableNushellIntegration = false;  # We handle this manually in nushell config
    nix-direnv.enable = true;  # Better Nix integration with caching
  };
  
}
