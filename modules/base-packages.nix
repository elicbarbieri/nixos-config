{ pkgs, nixvim }:
let
  # Build nixvim config
  nvim = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = import ../home/programs/nixvim;
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

    carapace
    direnv
    fd
    fzf
    gnupg
    ripgrep
    jq
    xxd
    tree
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
  ];

  # Development tools
  dev = with pkgs; [
    uv
    rustc
    cargo
    gcc
    nodejs
    python3
    bun
    go

    # c/c++
    clang

    # Kubernetes
    kubectl
    envsubst
    k9s
    kubernetes-helm

    # nix
    nix-prefetch-github
    nixos-anywhere
    cachix
    disko
  ];

in
{
  inherit cli dev;

  # Combined list for convenience
  common = cli ++ dev ++ [ nvim git nu starship atuin bat kitty zellij ];
}
