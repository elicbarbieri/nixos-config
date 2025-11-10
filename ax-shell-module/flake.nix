{
  description = "Ax-Shell - Modern desktop shell for Wayland compositors with NixOS integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        # Packages for direct installation
        packages = {
          ax-shell = pkgs.callPackage ./nix/packages/ax-shell.nix {};
          fabric-cli = pkgs.callPackage ./nix/packages/fabric-cli.nix {};
          zed-fonts = pkgs.callPackage ./nix/packages/zed-fonts.nix {};
          default = self.packages.${system}.ax-shell;
        };

        # Formatter for consistent code style
        formatter = pkgs.alejandra;
      }
    ) // {
      # NixOS modules (system-independent)
      nixosModules = {
        ax-shell = import ./nix/modules/ax-shell.nix;
        default = self.nixosModules.ax-shell;
      };

      # Package overlays for easy integration
      overlays = {
        default = final: prev: {
          ax-shell = prev.callPackage ./nix/packages/ax-shell.nix {};
        };
      };
    };
}
