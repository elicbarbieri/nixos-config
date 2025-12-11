{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.05";

  programs.direnv = {
    enable = true;
    silent = true;
    enableNushellIntegration = false;  # We handle this manually in nushell config
    nix-direnv.enable = true;  # Better Nix integration with caching
  };

}
