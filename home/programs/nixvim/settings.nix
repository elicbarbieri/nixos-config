{ ... }: {
  opts = {
      # Line numbers
      number = true;
      relativenumber = true;
      
      # Tabs & Indentation
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      autoindent = true;
      
      # Line wrapping
      wrap = false;
      
      # Search
      ignorecase = true;
      smartcase = true;
      
      # Appearance
      termguicolors = true;
      background = "dark";
      signcolumn = "yes";
      
      # Backspace
      backspace = "indent,eol,start";
      
      # Clipboard
      clipboard = "unnamedplus";
      
      # Split windows
      splitright = true;
      splitbelow = true;
      
      # Consider - as part of keyword
      iskeyword = "@,48-57,_,192-255,-";
      
      # Disable swap/backup
      swapfile = false;
      backup = false;
      
      # Undo
      undofile = true;
      
      # Update time
      updatetime = 250;
      timeoutlen = 300;
      
      # Scroll offset
      scrolloff = 8;
      
      # Show mode
      showmode = false;
    };
    
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };
  
  # Shell and clipboard configuration (from LazyVim)
  extraConfigLua = ''
    -- Set Nushell as the shell for Neovim
    if vim.fn.executable("nu") == 1 then
      vim.opt.shell = "nu"
      vim.opt.shellcmdflag = "--commands"
      vim.opt.shellredir = "| save --force %s"
      vim.opt.shellpipe = "| save --force %s"
      vim.opt.shellquote = ""
      vim.opt.shellxquote = ""
    end

    -- Clipboard configuration
    if vim.env.SSH_CLIENT then
      vim.g.clipboard = {
        name = "OSC 52",
        copy = {
          ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
          ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
        },
        paste = {
          ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
          ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
        },
      }
    else
      vim.g.clipboard = {
        name = "wl-clipboard",
        copy = {
          ["+"] = "wl-copy",
          ["*"] = "wl-copy --primary",
        },
        paste = {
          ["+"] = "wl-paste --no-newline",
          ["*"] = "wl-paste --no-newline --primary",
        },
        cache_enabled = 1,
      }
    end
  '';
}
