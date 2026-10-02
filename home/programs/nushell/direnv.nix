''
$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD? | default [] | append {||
  if (which direnv | is-empty) {
    return
  }

  direnv export json
  | from json
  | default {}
  | load-env

  # load-env skips ENV_CONVERSIONS (PATH arrives as string)
  if ($env.PATH | describe) == "string" {
    $env.PATH = ($env.PATH | split row (char esep))
  }
})
''
