''
# direnv hook for nushell
# This automatically loads/unloads environments when changing directories

# Add direnv hook to PWD changes
$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD? | default [] | append {||
  if (which direnv | is-empty) {
    return
  }

  direnv export json
  | from json
  | default {}
  | load-env

  # Convert PATH back to a list if direnv made it a string
  if ($env.PATH | describe) == "string" {
    $env.PATH = ($env.PATH | split row (char esep))
  }
})
''
