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
      # Environment Variables
      $env.config.show_banner = false
      $env.config.buffer_editor = "nvim"
      $env.EDITOR = "nvim"

      # NIX-LD Support (for running non-NixOS binaries)
      if "NIX_LD_LIBRARY_PATH" in $env {
          $env.LD_LIBRARY_PATH = $env.NIX_LD_LIBRARY_PATH
      }

      # Triton CUDA library path (NixOS standard location for NVIDIA libs)
      $env.TRITON_LIBCUDA_PATH = "/run/opengl-driver/lib"

      # Path Configuration
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
