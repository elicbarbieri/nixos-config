{ pkgs, ... }: {
  plugins.markdown-preview = {
    enable = true;
    settings = {
      # Auto-close preview when changing buffers or leaving markdown file
      auto_close = 1;

      # Refresh on buffer save or leaving insert mode
      refresh_slow = 0;

      # Custom function to open preview in Brave with --app flag
      browserfunc = "OpenMarkdownPreview";

      # Echo preview page URL in command line
      echo_preview_url = 1;

      # Port for the preview server (empty = auto-select random port)
      port = "";

      # Preview page title
      page_title = "Markdown Preview - 「\${name}」";

      # Use custom IP for the preview server
      # Empty string = auto-select based on your network
      open_ip = "";

      # Theme for the preview (dark or light)
      theme = "dark";
    };
  };

  # Custom browser function for opening preview using layoutmsg preselect for right-side positioning
  extraConfigVim = ''
    function! OpenMarkdownPreview(url)
      execute "silent ! hyprctl dispatch layoutmsg preselect r ; brave --app=" . a:url . " &"
    endfunction
  '';

  # Keymaps for markdown preview
  keymaps = [
    {
      mode = "n";
      key = "<leader>up";
      action = "<cmd>MarkdownPreview<cr>";
      options.desc = "Markdown Preview";
    }
    {
      mode = "n";
      key = "<leader>uP";
      action = "<cmd>MarkdownPreviewStop<cr>";
      options.desc = "Stop Markdown Preview";
    }
  ];
}
