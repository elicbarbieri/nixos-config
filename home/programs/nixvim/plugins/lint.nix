{ ... }: {
  plugins.lint = {
    enable = true;
    
    lintersByFt = {
      markdown = ["markdownlint-cli2"];
      sql = ["sqlfluff"];
      nix = ["nix"];
    };
  };
  
  # Custom linter configuration (inline the markdownlint config)
  extraConfigLua = ''
    local lint = require('lint')
    
    -- Configure markdownlint-cli2 to disable certain rules
    -- MD013: Line length (disabled - too strict)
    -- MD033: Inline HTML (disabled - needed for some markdown)
    lint.linters['markdownlint-cli2'].args = {
      "--config",
      '{"MD013": false, "MD033": false}',
    }
    
    -- Auto-lint on save and buffer enter
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  '';
}
