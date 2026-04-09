{ pkgs, isDesktop ? false, ... }: {
  plugins.vimtex = {
    enable = true;

    # Disable vimtex's defaults — we provide our own via extraPackages
    texlivePackage = null;
    zathuraPackage = null;

    settings = {
      # Use zathura as the PDF viewer (auto-reloads, SyncTeX support)
      view_method = "zathura";

      # Use latexmk for continuous compilation
      compiler_method = "latexmk";

      # latexmk args: continuous mode with synctex enabled
      compiler_latexmk = {
        options = [
          "-pdf"
          "-interaction=nonstopmode"
          "-synctex=1"
        ];
      };

      # Don't open quickfix window on warnings, only on errors
      quickfix_mode = 2;

    };
  };

  # Add texlab LSP for LaTeX
  plugins.lsp.servers.texlab = {
    enable = true;
    settings = {
      texlab = {
        build = {
          executable = "latexmk";
          args = [ "-pdf" "-interaction=nonstopmode" "-synctex=1" "%f" ];
          onSave = true;
        };
        forwardSearch = {
          executable = "zathura";
          args = [ "--synctex-forward" "%l:1:%f" "%p" ];
        };
      };
    };
  };

  # Open zathura on the right side (same pattern as markdown preview)
  extraConfigVim = ''
    function! OpenLatexPreview()
      execute "silent ! hyprctl dispatch layoutmsg preselect r"
      VimtexCompile
    endfunction
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>ut";
      action = "<cmd>call OpenLatexPreview()<cr>";
      options.desc = "LaTeX Preview (compile + view)";
    }
    {
      mode = "n";
      key = "<leader>uT";
      action = "<cmd>VimtexStop<cr>";
      options.desc = "Stop LaTeX Compilation";
    }
    {
      mode = "n";
      key = "<leader>uv";
      action = "<cmd>VimtexView<cr>";
      options.desc = "View LaTeX PDF";
    }
  ];

  extraPackages = with pkgs; [
    (if isDesktop then texliveFull else texliveSmall)
  ] ++ pkgs.lib.optionals isDesktop [
    pkgs.zathura
  ];
}
