module completions {

  # An extremely fast Python type checker.
  export extern ty [
    --help(-h)                # Print help
    --version(-V)             # Print version
  ]

  def "nu-complete ty check python_version" [] {
    [ "3.7" "3.8" "3.9" "3.10" "3.11" "3.12" "3.13" ]
  }

  def "nu-complete ty check output_format" [] {
    [ "full" "concise" ]
  }

  def "nu-complete ty check color" [] {
    [ "auto" "always" "never" ]
  }

  # Check a project for type errors
  export extern "ty check" [
    ...paths: string          # List of files or directories to check [default: the project root]
    --project: string         # Run the command within the given project directory
    --python: string          # Path to the Python environment
    --typeshed: string        # Custom directory to use for stdlib typeshed stubs
    --extra-search-path: string # Additional path to use as a module-resolution source (can be passed multiple times)
    --python-version: string@"nu-complete ty check python_version" # Python version to assume when resolving types
    --python-platform: string # Target platform to assume when resolving types
    --verbose(-v)             # Use verbose output (or `-vv` and `-vvv` for more verbose output)
    --error: string           # Treat the given rule as having severity 'error'. Can be specified multiple times.
    --warn: string            # Treat the given rule as having severity 'warn'. Can be specified multiple times.
    --ignore: string          # Disables the rule. Can be specified multiple times.
    --config(-c): string      # A TOML `<KEY> = <VALUE>` pair overriding a specific configuration option.
    --config-file: string     # The path to a `ty.toml` file to use for configuration
    --output-format: string@"nu-complete ty check output_format" # The format to use for printing diagnostic messages
    --color: string@"nu-complete ty check color" # Control when colored output is used
    --error-on-warning        # Use exit code 1 if there are any warning-level diagnostics
    --exit-zero               # Always use exit code 0, even when there are error-level diagnostics
    --watch(-W)               # Watch files for changes and recheck files related to the changed files
    --respect-ignore-files    # Respect file exclusions via `.gitignore` and other standard ignore files. Use `--no-respect-gitignore` to disable
    --no-respect-ignore-files
    --help(-h)                # Print help (see more with '--help')
  ]

  # Start the language server
  export extern "ty server" [
    --help(-h)                # Print help
  ]

  # Display ty's version
  export extern "ty version" [
    --help(-h)                # Print help
  ]

  def "nu-complete ty generate-shell-completion shell" [] {
    [ "bash" "elvish" "fish" "nushell" "powershell" "zsh" ]
  }

  # Generate shell completion
  export extern "ty generate-shell-completion" [
    shell: string@"nu-complete ty generate-shell-completion shell"
    --help(-h)                # Print help
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "ty help" [
  ]

  # Check a project for type errors
  export extern "ty help check" [
  ]

  # Start the language server
  export extern "ty help server" [
  ]

  # Display ty's version
  export extern "ty help version" [
  ]

  # Generate shell completion
  export extern "ty help generate-shell-completion" [
  ]

  # Print this message or the help of the given subcommand(s)
  export extern "ty help help" [
  ]

}

export use completions *
