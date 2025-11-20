''
# Custom prompt with direnv/nix environment indicator
def create_left_prompt [] {
  # Environment indicator (direnv/nix)
  let env_indicator = if ($env.DIRENV_DIR? != null) {
    $"(ansi cyan_bold)[nix](ansi reset) "
  } else {
    ""
  }
  
  # Directory path with colors
  let dir = match (do -i { $env.PWD | path relative-to $nu.home-path }) {
    null => $env.PWD
    "" => '~'
    $relative_pwd => ([~ $relative_pwd] | path join)
  }
  
  let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
  let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
  let path_segment = $"($path_color)($dir)(ansi reset)"
  let formatted_path = $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
  
  # Combine: [nix] /path/to/dir
  $"($env_indicator)($formatted_path)"
}

def create_right_prompt [] {
  # Show git branch if in a git repo
  let git_branch = (do -i { 
    git rev-parse --abbrev-ref HEAD 
  } | complete | get stdout | str trim)
  
  if ($git_branch | is-empty) {
    ""
  } else {
    $"(ansi yellow)($git_branch)(ansi reset)"
  }
}

# Set the prompts
$env.PROMPT_COMMAND = { || create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = { || create_right_prompt }
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }
''
