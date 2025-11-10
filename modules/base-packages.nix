{ pkgs, nixvim }:
let
  # Build nixvim config
  nvim = nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
    inherit pkgs;
    module = import ../home/programs/nixvim;
  };

  # CLI tools
  cli = with pkgs; [
    kitty
    nushell
    atuin
    carapace
    bat
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
    git
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
    helm
  ];
  
in
{
  inherit cli dev;
  
  # Combined list for convenience
  common = cli ++ dev ++ [ nvim ];
}
