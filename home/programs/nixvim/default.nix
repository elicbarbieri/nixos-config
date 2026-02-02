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
    ./plugins/dadbod.nix
  ];

  extraPackages = with pkgs; [
    # Add linter packages needed by nvim-lint and formatters
    markdownlint-cli2
    (python3.withPackages (ps: [ ps.mdformat-gfm ]))  # Markdown formatter with GFM table support
    sqlfluff
    nixpkgs-fmt
    shfmt

    # Add database tools needed by vim-dadbod
    postgresql  # Provides psql executable
    sqlite      # SQLite database and sqlite3 command-line tool
  ];
}
