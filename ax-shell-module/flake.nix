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

        # Development shell for working on ax-shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python development
            python3
            python3Packages.pip
            python3Packages.virtualenv
            python3Packages.build
            python3Packages.setuptools
            python3Packages.wheel
            
            # NixOS development
            nixos-rebuild
            nix-output-monitor
            alejandra
            
            # Testing and validation
            git
          ];
          
          shellHook = ''
            echo "🚀 Ax-Shell Development Environment"
            echo "Available commands:"
            echo "  nix build .#ax-shell     - Build ax-shell package"
            echo "  nix flake check          - Validate flake structure"
            echo "  nixos-rebuild test       - Test NixOS module integration"
          '';
        };

        # Formatter for consistent code style
        formatter = pkgs.alejandra;

        # NixOS VM tests
        checks = {
          vm-test = pkgs.nixosTest {
            name = "ax-shell-integration";
            
            nodes.machine = { ... }: {
              imports = [ self.nixosModules.default ];
              
              programs.ax-shell = {
                enable = true;
                terminalCommand = "echo 'test-terminal'";
              };
              
              # Minimal test environment
              users.users.test = {
                isNormalUser = true;
                password = "test";
              };
              
              # Enable required services for testing
              services.xserver.enable = true;
              services.displayManager.sddm.enable = true;
            };
            
            testScript = ''
              machine.wait_for_unit("multi-user.target")
              machine.succeed("command -v ax-shell")
              machine.succeed("test -f /etc/ax-shell/config.json")
              machine.succeed("test -f /etc/ax-shell/styles.css")
              
              # Verify session file exists
              machine.succeed("test -f /run/current-system/sw/share/wayland-sessions/ax-shell.desktop")
              
              # Test configuration generation
              config_content = machine.succeed("cat /etc/ax-shell/config.json")
              assert '"terminal_command": "echo \'test-terminal\'"' in config_content
            '';
          };
        };
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

      # Templates for users
      templates = {
        basic = {
          path = ./examples/basic-configuration;
          description = "Basic ax-shell configuration";
        };
        advanced = {
          path = ./examples/advanced-theming;
          description = "Advanced ax-shell configuration with custom theming";
        };
      };
    };
}