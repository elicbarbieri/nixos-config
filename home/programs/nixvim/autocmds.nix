{ ... }: {
  autoCmd = [
      # Highlight on yank
      {
        event = ["TextYankPost"];
        pattern = "*";
        callback = {
          __raw = ''
            function()
              vim.highlight.on_yank()
            end
          '';
        };
      }
      
      # Remove trailing whitespace on save
      {
        event = ["BufWritePre"];
        pattern = "*";
        command = "%s/\\s\\+$//e";
      }
      
      # Restore cursor position
      {
        event = ["BufReadPost"];
        pattern = "*";
        callback = {
          __raw = ''
            function()
              if vim.fn.line("'\"") > 0 and vim.fn.line("'\"") <= vim.fn.line("$") then
                vim.fn.setpos(".", vim.fn.getpos("'\""))
                vim.cmd("silent! foldopen")
              end
            end
          '';
        };
      }
    ];
}
