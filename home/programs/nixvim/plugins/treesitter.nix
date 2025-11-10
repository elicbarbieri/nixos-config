{ ... }: {
  plugins = {
    treesitter = {
      enable = true;
      
      settings = {
        highlight.enable = true;
        indent.enable = true;
        
        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<C-space>";
            node_incremental = "<C-space>";
            scope_incremental = false;
            node_decremental = "<bs>";
          };
        };
      };
    };
    
    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 3;
      };
    };
    
    treesitter-textobjects = {
      enable = true;
      settings = {
        select = {
          enable = true;
          lookahead = true;
          keymaps = {
            "af" = "@function.outer";
            "if" = "@function.inner";
            "ac" = "@class.outer";
            "ic" = "@class.inner";
          };
        };
      };
    };
    
    ts-autotag.enable = true;
  };
}
