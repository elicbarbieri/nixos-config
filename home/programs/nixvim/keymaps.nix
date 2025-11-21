{ ... }: {
  keymaps = [
      # Better window navigation
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Move to left window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Move to bottom window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Move to top window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Move to right window";
      }

      # Buffer navigation
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Previous buffer";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options.desc = "Next buffer";
      }
      {
        mode = "n";
        key = "[b";
        action = "<cmd>bprevious<cr>";
        options.desc = "Prev Buffer";
      }
      {
        mode = "n";
        key = "]b";
        action = "<cmd>bnext<cr>";
        options.desc = "Next Buffer";
      }

      # Stay in indent mode
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options.desc = "Indent left";
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options.desc = "Indent right";
      }

      # Move lines up and down (LazyVim style with Alt+j/k)
      {
        mode = "n";
        key = "<A-j>";
        action = "<cmd>m .+1<CR>==";
        options.desc = "Move Down";
      }
      {
        mode = "n";
        key = "<A-k>";
        action = "<cmd>m .-2<CR>==";
        options.desc = "Move Up";
      }
      {
        mode = "i";
        key = "<A-j>";
        action = "<Esc><cmd>m .+1<CR>==gi";
        options.desc = "Move Down";
      }
      {
        mode = "i";
        key = "<A-k>";
        action = "<Esc><cmd>m .-2<CR>==gi";
        options.desc = "Move Up";
      }
      {
        mode = "v";
        key = "<A-j>";
        action = ":m '>+1<CR>gv=gv";
        options.desc = "Move Down";
      }
      {
        mode = "v";
        key = "<A-k>";
        action = ":m '<-2<CR>gv=gv";
        options.desc = "Move Up";
      }

      # Visual mode line movement (keep existing J/K for compatibility)
      {
        mode = "v";
        key = "J";
        action = ":m '>+1<CR>gv=gv";
        options.desc = "Move Lines Down";
      }
      {
        mode = "v";
        key = "K";
        action = ":m '<-2<CR>gv=gv";
        options.desc = "Move Lines Up";
      }

      # Better paste
      {
        mode = "v";
        key = "p";
        action = ''"_dP'';
        options.desc = "Paste without yanking";
      }

      # Search result centering (LazyVim style)
      {
        mode = ["n" "x" "o"];
        key = "n";
        action = "nzzzv";
        options.desc = "Next Search Result";
      }
      {
        mode = ["n" "x" "o"];
        key = "N";
        action = "Nzzzv";
        options.desc = "Prev Search Result";
      }

      # Clear search highlighting (LazyVim style)
      {
        mode = ["i" "n" "s"];
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR><Esc>";
        options.desc = "Escape and Clear hlsearch";
      }

      # Diagnostic navigation (LazyVim defaults)
      {
        mode = "n";
        key = "]d";
        action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
        options.desc = "Next Diagnostic";
      }
      {
        mode = "n";
        key = "[d";
        action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
        options.desc = "Prev Diagnostic";
      }
      {
        mode = "n";
        key = "]e";
        action = "<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})<CR>";
        options.desc = "Next Error";
      }
      {
        mode = "n";
        key = "[e";
        action = "<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})<CR>";
        options.desc = "Prev Error";
      }
      {
        mode = "n";
        key = "]w";
        action = "<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.WARN})<CR>";
        options.desc = "Next Warning";
      }
      {
        mode = "n";
        key = "[w";
        action = "<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.WARN})<CR>";
        options.desc = "Prev Warning";
      }
      {
        mode = "n";
        key = "<leader>cd";
        action = "<cmd>lua vim.diagnostic.open_float()<CR>";
        options.desc = "Line Diagnostics";
      }

      # Save file (LazyVim default - works in multiple modes)
      {
        mode = ["n" "i" "v"];
        key = "<C-s>";
        action = "<cmd>w<CR><Esc>";
        options.desc = "Save File";
      }

      # Window/Split management (LazyVim <leader>w namespace)
      {
        mode = "n";
        key = "<leader>wv";
        action = "<cmd>vsplit<CR>";
        options.desc = "Split Window Right";
      }
      {
        mode = "n";
        key = "<leader>wh";
        action = "<cmd>split<CR>";
        options.desc = "Split Window Below";
      }
      {
        mode = "n";
        key = "<leader>wd";
        action = "<cmd>close<CR>";
        options.desc = "Delete Window";
      }
      {
        mode = "n";
        key = "<leader>|";
        action = "<cmd>vsplit<CR>";
        options.desc = "Split Window Right";
      }
      {
        mode = "n";
        key = "<leader>-";
        action = "<cmd>split<CR>";
        options.desc = "Split Window Below";
      }

      # Window resize (LazyVim defaults)
      {
        mode = "n";
        key = "<C-Up>";
        action = "<cmd>resize +2<CR>";
        options.desc = "Increase Window Height";
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = "<cmd>resize -2<CR>";
        options.desc = "Decrease Window Height";
      }
      {
        mode = "n";
        key = "<C-Left>";
        action = "<cmd>vertical resize -2<CR>";
        options.desc = "Decrease Window Width";
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = "<cmd>vertical resize +2<CR>";
        options.desc = "Increase Window Width";
      }

      # Buffer management (LazyVim <leader>b namespace)
      {
        mode = "n";
        key = "<leader>bd";
        action = "<cmd>bd<CR>";
        options.desc = "Delete Buffer";
      }
      {
        mode = "n";
        key = "<leader>bo";
        action = "<cmd>%bd|e#|bd#<CR>";
        options.desc = "Delete Other Buffers";
      }
      {
        mode = "n";
        key = "<leader>bb";
        action = "<cmd>e #<CR>";
        options.desc = "Switch to Other Buffer";
      }
      {
        mode = "n";
        key = "<leader>`";
        action = "<cmd>e #<CR>";
        options.desc = "Switch to Other Buffer";
      }

      # Tab management (LazyVim <leader><tab> namespace)
      {
        mode = "n";
        key = "<leader><tab>l";
        action = "<cmd>tablast<CR>";
        options.desc = "Last Tab";
      }
      {
        mode = "n";
        key = "<leader><tab>f";
        action = "<cmd>tabfirst<CR>";
        options.desc = "First Tab";
      }
      {
        mode = "n";
        key = "<leader><tab><tab>";
        action = "<cmd>tabnew<CR>";
        options.desc = "New Tab";
      }
      {
        mode = "n";
        key = "<leader><tab>]";
        action = "<cmd>tabnext<CR>";
        options.desc = "Next Tab";
      }
      {
        mode = "n";
        key = "<leader><tab>[";
        action = "<cmd>tabprevious<CR>";
        options.desc = "Previous Tab";
      }
      {
        mode = "n";
        key = "<leader><tab>d";
        action = "<cmd>tabclose<CR>";
        options.desc = "Close Tab";
      }
      {
        mode = "n";
        key = "<leader><tab>o";
        action = "<cmd>tabonly<CR>";
        options.desc = "Close Other Tabs";
      }

      # Quit/Session (LazyVim <leader>q namespace)
      {
        mode = "n";
        key = "<leader>qq";
        action = "<cmd>qa<CR>";
        options.desc = "Quit All";
      }

      # Location & Quickfix lists (LazyVim <leader>x namespace)
      {
        mode = "n";
        key = "<leader>xl";
        action = "<cmd>lopen<CR>";
        options.desc = "Location List";
      }
      {
        mode = "n";
        key = "<leader>xq";
        action = "<cmd>copen<CR>";
        options.desc = "Quickfix List";
      }

      # Add comment below/above (LazyVim gco and gcO)
      {
        mode = "n";
        key = "gco";
        action = "o<Esc>Vcx<Esc><cmd>normal gcc<CR>fxa<BS>";
        options.desc = "Add Comment Below";
      }
      {
        mode = "n";
        key = "gcO";
        action = "O<Esc>Vcx<Esc><cmd>normal gcc<CR>fxa<BS>";
        options.desc = "Add Comment Above";
      }

      # Toggle options (LazyVim <leader>u namespace)
      {
        mode = "n";
        key = "<leader>us";
        action = "<cmd>set spell!<CR>";
        options.desc = "Toggle Spelling";
      }
      {
        mode = "n";
        key = "<leader>uw";
        action = "<cmd>set wrap!<CR>";
        options.desc = "Toggle Wrap";
      }
      {
        mode = "n";
        key = "<leader>uL";
        action = "<cmd>set relativenumber!<CR>";
        options.desc = "Toggle Relative Number";
      }
      {
        mode = "n";
        key = "<leader>ul";
        action = "<cmd>set number!<CR>";
        options.desc = "Toggle Line Numbers";
      }
      {
        mode = "n";
        key = "<leader>ud";
        action = "<cmd>lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<CR>";
        options.desc = "Toggle Diagnostics";
      }
      {
        mode = "n";
        key = "<leader>uc";
        action = "<cmd>let &conceallevel = (&conceallevel == 0) ? 2 : 0<CR>";
        options.desc = "Toggle Conceal Level";
      }
      {
        mode = "n";
        key = "<leader>uh";
        action = "<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<CR>";
        options.desc = "Toggle Inlay Hints";
      }
    ];
}
