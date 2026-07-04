{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Stable pin used ONLY for the CUDA dev shell. Stable point-releases move
    # slowly (backports/security), so the multi-gig CUDA closure stays cache-hot
    # and doesn't churn every time unstable bumps gcc/glibc/cuda. Intentionally
    # not `follows`-ed — the whole point is an independent, slow-moving pin.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
    ax-shell.url = "github:elicbarbieri/ax-shell";
    ax-shell.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # nixvim intentionally does NOT follow nixpkgs: keeping its own pin lets us
    # pull prebuilt plugins from the nix-community Cachix instead of rebuilding
    # from source (see modules/base-packages.nix).
    nixvim.url = "github:nix-community/nixvim";
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, hyprland, ax-shell, home-manager, disko, nixvim, nix-flatpak, sops-nix, vpn-confinement, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    # Stable nixpkgs, used only for the CUDA dev shell (see nixpkgs-stable input).
    pkgsStable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };

    # Build a NixOS host from a host module plus profile-specific extras,
    # factoring out the wiring shared by every machine (common config, disko,
    # sops, home-manager). Keeps each host declaration to its distinct parts.
    mkHost = { host, hmProfile, extraModules ? [ ] }:
      nixpkgs.lib.nixosSystem {
        specialArgs = { inherit hyprland self ax-shell nixvim sops-nix; };
        modules = [
          { nixpkgs.hostPlatform = system; }
          host
          ./modules/common.nix
          ./modules/nebula.nix
          ./modules/vm-variant.nix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.elicb = import hmProfile;
            home-manager.extraSpecialArgs = { inherit nixvim; };
          }
        ] ++ extraModules;
      };

    # Modules shared by the graphical hosts (Hyprland + Ax-Shell desktop).
    # CUDA is deliberately absent here — it lives in the `cuda` specialisation
    # (modules/desktop) to keep it out of the default closure.
    desktopModules = [
      ./modules/desktop
      hyprland.nixosModules.default
      ax-shell.nixosModules.ax-shell
      nix-flatpak.nixosModules.nix-flatpak
    ];
  in
  {
    # Export ax-shell module for easy redistribution
    nixosModules.ax-shell = ax-shell.nixosModules.default;

    # Export packages for easy access
    packages.${system}.ax-shell = ax-shell.packages.${system}.default;

    formatter.${system} = pkgs.nixfmt-rfc-style;

    # Ephemeral dev shells
    devShells.${system} = {
      default = let
        basePackages = import ./modules/base-packages.nix { inherit pkgs nixvim; isDesktop = true; };
      in
        pkgs.mkShell {
          packages = basePackages.common ++ (with pkgs; [
            nixfmt-rfc-style  # formatter
            deadnix           # dead-code linter
            statix            # anti-pattern linter
          ]);

          shellHook = ''
            echo "Elicb Dev Shell"

            # Auto-start nushell if not already in it
            if [ -z "$NUSHELL_VERSION" ] && command -v nu &> /dev/null; then
              exec nu
            fi
          '';
        };

      # CUDA / ML toolchain, on demand: `nix develop .#cuda` (or wire into a
      # project's .envrc with `use flake <this-flake>#cuda`). Built from the
      # stable pin so the huge CUDA store paths stay cache-hot across unstable
      # bumps. Replaces the old system-wide nvidia-cuda module: CUDA is no longer
      # part of any system generation, so it's GC-collectable when unused.
      cuda = pkgsStable.mkShell {
        packages = with pkgsStable; [ cmake ninja cudaPackages.cudatoolkit ];
        shellHook = ''
          export CUDA_HOME=${pkgsStable.cudaPackages.cudatoolkit}
          export CUDA_PATH=$CUDA_HOME
          export LIBRARY_PATH=$CUDA_HOME/lib:$CUDA_HOME/lib/stubs
          export CPATH=$CUDA_HOME/include
          # NVIDIA userspace driver libs come from the running system, not the pin.
          export TRITON_LIBCUDA_PATH=/run/opengl-driver/lib
          export LD_LIBRARY_PATH=${pkgsStable.lib.makeLibraryPath (with pkgsStable.cudaPackages; [
            cuda_cudart cuda_nvrtc libcublas libcufft libcusparse libcusolver
            cudnn nccl libcurand
          ])}:/run/opengl-driver/lib
          echo "CUDA dev shell (nixpkgs-stable) — cudatoolkit at $CUDA_HOME"
        '';
      };
    };

    nixosConfigurations = {
      # Dell XPS 17 9730 — Hyprland desktop, Intel + NVIDIA (PRIME offload)
      elicb-xps = mkHost {
        host = ./hosts/elicb-xps;
        hmProfile = ./home/desktop.nix;
        extraModules = desktopModules;
      };

      # Dell Desktop — Hyprland desktop, RTX 2070 Super
      elicb-dell-desktop = mkHost {
        host = ./hosts/elicb-dell-desktop;
        hmProfile = ./home/desktop.nix;
        extraModules = desktopModules;
      };

      # Home Server — headless (no desktop/performance modules)
      elicb-home-server = mkHost {
        host = ./hosts/elicb-home-server;
        hmProfile = ./home/base.nix;
        extraModules = [ vpn-confinement.nixosModules.default ];
      };
    };
  };
}
