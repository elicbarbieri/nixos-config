{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    ax-shell.url = "path:./ax-shell-module/";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, hyprland, ax-shell, home-manager, disko, ... }: {

    # Export ax-shell module for easy redistribution
    nixosModules = {
      ax-shell = ax-shell.nixosModules.default;
      default = self.nixosModules.ax-shell;
    };

    # Export packages for easy access
    packages.x86_64-linux = {
      ax-shell = ax-shell.packages.x86_64-linux.default;
      default = self.packages.x86_64-linux.ax-shell;
    };

    nixosConfigurations = {
      # Dell XPS 17 9730 configuration  
      elicb-xps = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/elicb-xps
          ./modules/common.nix
          ./modules/desktop
          ./modules/performance
          ./modules/vm-variant.nix
          hyprland.nixosModules.default
          ax-shell.nixosModules.default
          disko.nixosModules.disko
          
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.elicb = import ./home;
          }
        ];
        specialArgs = { inherit hyprland self ax-shell; };
      };
    };
  };
}
