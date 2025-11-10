{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    ax-shell.url = "path:./ax-shell-module/";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, hyprland, ax-shell, home-manager, disko, nixvim, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Export ax-shell module for easy redistribution
    nixosModules = {
      ax-shell = ax-shell.nixosModules.default;
    };

    # Export packages for easy access
    packages.x86_64-linux = {
      ax-shell = ax-shell.packages.x86_64-linux.default;
    };
    
    # Ephemeral dev shells
    devShells.x86_64-linux = let
      basePackages = import ./modules/base-packages.nix { inherit pkgs nixvim; };
    in {
      default = pkgs.mkShell {
        packages = basePackages.common;
        
        shellHook = ''
          echo "Elicb Dev Shell"
          
          # Auto-start nushell if not already in it
          if [ -z "$NUSHELL_VERSION" ] && command -v nu &> /dev/null; then
            exec nu
          fi
        '';
      };
    };

    nixosConfigurations = {
      # Dell XPS 17 9730 configuration  
      elicb-xps = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/elicb-xps
          ./modules/common.nix
          ./modules/desktop
          ./modules/vm-variant.nix
          hyprland.nixosModules.default
          ax-shell.nixosModules.ax-shell
          disko.nixosModules.disko
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.elicb = import ./home/desktop.nix;
            home-manager.extraSpecialArgs = { inherit nixvim; };
          }
        ];
        specialArgs = { inherit hyprland self ax-shell nixvim; };
      };

      # Home Server configuration
      elicb-home-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/elicb-home-server
          ./modules/common.nix
          # Note: No desktop or performance modules for server
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.elicb = import ./home/server.nix;
            home-manager.extraSpecialArgs = { inherit nixvim; };
          }
        ];
        specialArgs = { inherit self nixvim; };
      };
    };
  };
}
