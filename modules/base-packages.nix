{ pkgs, nixvim }:
let
  # Build nixvim config
  nvim = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = import ../home/programs/nixvim;
  };

  # Build git with personal config
  git = import ../home/programs/git.nix { inherit pkgs; };

  # Build starship with personal config
  starship = import ../home/programs/starship.nix { inherit pkgs; };

  # Build nushell with personal config (needs starship for init scripts)
  nu = import ../home/programs/nushell { inherit pkgs starship; };

  # Build atuin with personal config
  atuin = import ../home/programs/atuin { inherit pkgs; };

  # Build bat with personal config
  bat = import ../home/programs/bat.nix { inherit pkgs; };

  # Build kitty with personal config
  kitty = import ../home/programs/kitty.nix { inherit pkgs; };

  # Build zellij with personal config
  zellij = import ../home/programs/zellij.nix { inherit pkgs; };

  # CLI tools
  cli = with pkgs; [
    carapace
    direnv
    fd
    fzf
    gnupg
    ripgrep
    tree
    traceroute
    arp-scan
    iperf3
    lazydocker
    lazygit
    btop
    tmux
    wl-clipboard  # Required for zellij clipboard support
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
    kubectl
    k9s
    kubernetes-helm
  ];

in
{
  inherit cli dev;

  # Combined list for convenience
  common = cli ++ dev ++ [ nvim git nu starship atuin bat kitty zellij ];
}
