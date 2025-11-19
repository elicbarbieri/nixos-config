{ config, pkgs, lib, ... }:

let
  completions = import ./completions.nix { inherit pkgs; };
  shellConfig = import ./config.nix { };
  keybindings = import ./keybindings.nix { };
  aliases = import ./aliases.nix { };
  
in {
  programs.nushell = {
    enable = true;
    
    extraEnv = ''
      # Nushell-specific configuration
      # Note: Most environment variables are set in NixOS config (common.nix)
      # and automatically available here via environment.sessionVariables
      $env.config.show_banner = false
      $env.config.buffer_editor = "nvim"

      # NIX-LD Support (for running non-NixOS binaries like Python packages)
      # NixOS sets NIX_LD_LIBRARY_PATH, we just need to expose it as LD_LIBRARY_PATH
      # so that Python and other tools can find the dynamically linked libraries
      if "NIX_LD_LIBRARY_PATH" in $env {
          $env.LD_LIBRARY_PATH = $env.NIX_LD_LIBRARY_PATH
      }

      # Path Configuration (user-specific paths)
      # Note: Keep in sync with home/base.nix sessionPath
      $env.PATH = ($env.PATH | split row (char esep))
      $env.PATH = ($env.PATH | prepend $"($env.HOME)/.cargo/bin")
      $env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin")
      $env.PATH = ($env.PATH | prepend $"($env.HOME)/.bun/bin")
    '';
    
    extraConfig = ''
      # Core configuration
      ${shellConfig.shellConfig}
      
      # Keybindings
      ${keybindings.keybindings}
      
      # Aliases and functions
      ${aliases.aliases}
      
      # Load auto-generated completions
      ${completions.sourceCompletions}
    '';
  };
}
