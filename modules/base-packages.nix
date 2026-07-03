{ pkgs, nixvim, isDesktop ? false }:
let
  # Build nixvim config
  # Use nixvim's own pinned nixpkgs (don't pass `pkgs`) so we hit the
  # nix-community Cachix instead of rebuilding plugins from source.
  nvim = nixvim.legacyPackages.${pkgs.stdenv.hostPlatform.system}.makeNixvimWithModule {
    module = import ../home/programs/nixvim;
    extraSpecialArgs = { inherit isDesktop; };
  };

  # Build wrapped programs with personal config bundled
  git = import ../home/programs/git.nix { inherit pkgs; };
  starship = import ../home/programs/starship.nix { inherit pkgs; };
  nu = import ../home/programs/nushell { inherit pkgs starship; };
  atuin = import ../home/programs/atuin { inherit pkgs; };
  bat = import ../home/programs/bat.nix { inherit pkgs; };
  kitty = import ../home/programs/kitty.nix { inherit pkgs; };
  zellij = import ../home/programs/zellij.nix { inherit pkgs; };

  # CLI tools
  cli = with pkgs; [
    # TODO: Bake in jj config w/ override
    jujutsu
    gh

    carapace
    direnv
    fd
    fzf
    gnupg
    ripgrep
    jq
    xxd
    tree
    tokei

    nebula
    traceroute
    arp-scan
    iperf3
    speedtest-cli
    iftop
    lazydocker
    lazygit
    lazyjj
    btop
    wl-clipboard
    age
    sops

    openssl
    lsof
    postgresql
  ];

  # Language toolchains and Nix tooling (all hosts)
  dev = with pkgs; [
    # Language toolchains
    uv
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
    gcc
    clang
    nodejs
    python3
    bun
    go

    # Nix tooling
    nix-prefetch-github
    nixos-anywhere
    cachix
    disko
  ];

  # Cloud / Kubernetes tooling (desktop hosts only — not needed headless)
  cloud = with pkgs; [
    kubectl
    kubectl-neat
    k9s
    kubernetes-helm
    envsubst
    awscli2
    google-cloud-sdk
  ];

in
{
  inherit cli dev cloud;

  # Combined list for convenience
  common =
    cli ++ dev
    ++ pkgs.lib.optionals isDesktop cloud
    ++ [ nvim git nu starship atuin bat kitty zellij ];
}
