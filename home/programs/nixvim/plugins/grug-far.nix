{ ... }: {
  plugins.grug-far = {
    enable = true;
  };

  keymaps = [
    {
      mode = ["n" "v"];
      key = "<leader>sr";
      action = "<cmd>GrugFar<cr>";
      options.desc = "Search and Replace";
    }
    {
      mode = ["n" "v"];
      key = "<leader>sR";
      action.__raw = ''
        function()
          require('grug-far').open({ prefills = { search = vim.fn.expand("<cword>") } })
        end
      '';
      options.desc = "Search and Replace (Current Word)";
    }
  ];
}
