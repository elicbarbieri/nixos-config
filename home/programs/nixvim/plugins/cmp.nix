{ ... }: {
  plugins = {
      luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
          store_selection_keys = "<Tab>";
        };
      };
      
      cmp = {
        enable = true;
        autoEnableSources = true;
        
        settings = {
          snippet.expand = ''
            function(args)
              require('luasnip').lsp_expand(args.body)
            end
          '';
          
          mapping = {
            __raw = ''
              cmp.mapping.preset.insert({
                ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                ['<C-f>'] = cmp.mapping.scroll_docs(4),
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<C-e>'] = cmp.mapping.abort(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ['<Up>'] = cmp.mapping.select_prev_item(),
                ['<Down>'] = cmp.mapping.select_next_item(),
                ['<Tab>'] = cmp.mapping(function(fallback)
                  if require('luasnip').expand_or_jumpable() then
                    require('luasnip').expand_or_jump()
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                  if require('luasnip').jumpable(-1) then
                    require('luasnip').jump(-1)
                  else
                    fallback()
                  end
                end, { 'i', 's' }),
              })
            '';
          };
          
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; }
            # vim-dadbod-completion added via FileType autocmd in dadbod.nix
          ];
          
          window = {
            completion = {
              border = "rounded";
              winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None";
            };
            documentation = {
              border = "rounded";
            };
          };
        };
      };
      
      cmp-nvim-lsp.enable = true;
      cmp-buffer.enable = true;
      cmp-path.enable = true;
      cmp_luasnip.enable = true;
      cmp-cmdline.enable = true;
      
      lspkind = {
        enable = true;
        settings = {
          cmp = {
            enable = true;
            menu = {
              nvim_lsp = "[LSP]";
              luasnip = "[Snippet]";
              buffer = "[Buffer]";
              path = "[Path]";
              vim-dadbod-completion = "[DB]";
            };
          };
        };
      };
    };
}
