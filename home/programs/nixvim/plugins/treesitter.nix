{ ... }: {
  plugins = {
    treesitter = {
      enable = true;
      highlight.enable = true;
      indent.enable = true;
    };

    treesitter-context = {
      enable = true;
      settings = {
        max_lines = 3;
      };
    };

    treesitter-textobjects = {
      enable = true;
    };

    ts-autotag.enable = true;
  };

  extraConfigLua = ''
    do
      local ok, ts_select = pcall(require, 'nvim-treesitter-textobjects.select')
      if ok then
        local maps = {
          af = '@function.outer',
          ['if'] = '@function.inner',
          ac = '@class.outer',
          ic = '@class.inner',
        }
        for lhs, query in pairs(maps) do
          for _, mode in ipairs({ 'x', 'o' }) do
            vim.keymap.set(mode, lhs, function()
              ts_select.select_textobject(query, 'textobjects')
            end, { silent = true, desc = 'Select ' .. query })
          end
        end
      end
    end
  '';
}
