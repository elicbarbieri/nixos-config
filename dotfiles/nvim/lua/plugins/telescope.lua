return {
  "telescope.nvim",
  opts = {
    hidden_files = true,
    defaults = {
      file_ignore_patterns = {
        "^%.git/",
        "node_modules/",
        ".venv/",
      },
    },
  },
}
