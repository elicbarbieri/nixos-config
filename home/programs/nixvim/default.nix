{ pkgs, ... }: {
  imports = [
    ./settings.nix
    ./keymaps.nix
    ./autocmds.nix
    ./plugins/colorschemes.nix
    ./plugins/lsp.nix
    ./plugins/cmp.nix
    ./plugins/supermaven.nix
    ./plugins/telescope.nix
    ./plugins/treesitter.nix
    ./plugins/ui.nix
    ./plugins/git.nix
    ./plugins/utils.nix
    ./plugins/lint.nix
    ./plugins/markdown.nix
  ];

  # These options are for home-manager
  # For standalone, they're handled by the wrapper
  viAlias = true;
  vimAlias = true;
}
