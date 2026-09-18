{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.05";

  # Single file, not the dir (~/.claude also holds mutable session/project state)
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "/home/elicb/nixos-config/dotfiles/claude/CLAUDE.md";

  programs.direnv = {
    enable = true;
    silent = true;
    enableNushellIntegration = false;  # We handle this manually in nushell config
    nix-direnv.enable = true;  # Better Nix integration with caching
  };

}
