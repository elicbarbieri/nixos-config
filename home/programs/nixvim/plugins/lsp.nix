{ ... }: {
  plugins = {
      lsp = {
        enable = true;
        
        keymaps = {
          # LazyVim LSP keymaps
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gr" = "references";
            "gI" = "implementation";
            "gy" = "type_definition";
            "K" = "hover";
            "gK" = "signature_help";
            "<leader>ca" = "code_action";
            "<leader>cr" = "rename";
            "<leader>cR" = "rename";  # Alternative
          };
        };
        
        servers = {
          # Nix
          nixd = {
            enable = true;
            settings = {
              formatting.command = ["nixfmt"];
            };
          };
          
          # Rust
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
          
          # Python
          pyright.enable = true;
          ruff.enable = true;
          
          # JavaScript/TypeScript
          ts_ls.enable = true;
          
          # JSON/YAML
          jsonls.enable = true;
          yamlls.enable = true;
          
          # Markdown
          marksman.enable = true;
          
          # Bash
          bashls.enable = true;
        };
      };
      
      # Formatting
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix = ["nixfmt"];
            rust = ["rustfmt"];
            python = ["ruff_format"];
            javascript = ["prettier"];
            typescript = ["prettier"];
            json = ["prettier"];
            yaml = ["prettier"];
            markdown = ["mdformat"];
            bash = ["shfmt"];
            sql = ["sqlfluff"];
          };
          
          # Configure sqlfluff formatter for PostgreSQL and SQLite
          formatters = {
            sqlfluff = {
              args = ["format" "--dialect=postgres" "-"];
            };
          };
          format_on_save = {
            lsp_fallback = true;
            timeout_ms = 500;
          };
        };
      };
      
      # LSP UI improvements
      fidget = {
        enable = true;
        settings = {
          notification = {
            window = {
              winblend = 0;
            };
          };
        };
      };
      
      # LSP lines (show diagnostics as virtual text)
      lsp-lines.enable = true;
    };
    
  # Keymaps for formatting and LSP
  keymaps = [
    # Formatting
    {
      mode = ["n" "v"];
      key = "<leader>cf";
      action = "<cmd>lua require('conform').format()<cr>";
      options.desc = "Format";
    }
    
    # Signature help in insert mode
    {
      mode = "i";
      key = "<C-k>";
      action = "<cmd>lua vim.lsp.buf.signature_help()<cr>";
      options.desc = "Signature Help";
    }
    
    # Code lens
    {
      mode = "n";
      key = "<leader>cc";
      action = "<cmd>lua vim.lsp.codelens.run()<cr>";
      options.desc = "Run Codelens";
    }
    {
      mode = "n";
      key = "<leader>cC";
      action = "<cmd>lua vim.lsp.codelens.refresh()<cr>";
      options.desc = "Refresh & Display Codelens";
    }
    
    # LSP Info
    {
      mode = "n";
      key = "<leader>cl";
      action = "<cmd>LspInfo<cr>";
      options.desc = "Lsp Info";
    }
    
    # Navigate references (LazyVim [[ and ]] - using illuminate)
    {
      mode = "n";
      key = "]]";
      action = "<cmd>lua require('illuminate').goto_next_reference(false)<cr>";
      options.desc = "Next Reference";
    }
    {
      mode = "n";
      key = "[[";
      action = "<cmd>lua require('illuminate').goto_prev_reference(false)<cr>";
      options.desc = "Prev Reference";
    }
  ];
}
