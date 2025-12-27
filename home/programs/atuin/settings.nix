{
  # Sync settings
  auto_sync = true;
  sync_frequency = "10m";

  # Search settings
  search_mode = "fuzzy";
  filter_mode = "global";

  # Display settings
  style = "compact";
  inline_height = 20;
  show_preview = true;
  max_preview_height = 4;
  show_help = true;

  # Behavior settings
  exit_mode = "return-original";
  keymap_mode = "emacs";

  # Workspace support
  workspaces = true;

  # Common prefixes and subcommands
  common_prefix = [ "sudo" ];
  common_subcommands = [
    "cargo"
    "git"
    "guardian"
    "kubectl"
    "docker"
    "systemctl"
    "make"
    "cmake"
    "uv"
  ];
}
