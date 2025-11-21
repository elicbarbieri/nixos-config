''
# direnv hook for nushell
# This automatically loads/unloads environments when changing directories

# Silence direnv's verbose export messages
$env.DIRENV_LOG_FORMAT = ""

# Add direnv hook to PWD changes
$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD? | default [] | append {||
  if (which direnv | is-empty) {
    return
  }
  
  direnv export json 
  | from json 
  | default {} 
  | load-env
})
''
