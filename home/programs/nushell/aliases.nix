''
# Development aliases
def kgp [] { kubectl get pods | detect columns }
def kgd [] { kubectl get deployments | detect columns }
alias d = docker
alias dc = docker compose
alias gs = git status
alias wt = git worktree

# Quick navigation
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..

# Utility functions
def l [dir?: path] {
    match $dir {
        null => (ls -la)
        _ => (ls -la $dir)
    } | select name type mode user size modified accessed
}

# Plugin installer utility
def install_plugin [plugin_name: string, git_repo_url: string, git_tag?: string] {
    let repo_dir = (mktemp -d | path join $plugin_name)
    ^git clone $git_repo_url $repo_dir
    cd $repo_dir

    if $git_tag != null {
        ^git checkout $git_tag
    }

    let nushell_version = ^nu --version
    let cargo_toml_path = ($repo_dir | path join "Cargo.toml")
    mut cargo_toml = open $cargo_toml_path

    if ($cargo_toml.dependencies.nu-protocol? == null) or ($cargo_toml.dependencies.nu-plugin? == null) {
        print $"(ansi red)Error: nu-protocol or nu-plugin not found in dependencies; cannot install plugin via script.(ansi reset)"
        return
    }

    if ($cargo_toml.dependencies."nu-protocol" != $nushell_version) or ($cargo_toml.dependencies."nu-plugin" != $nushell_version) {
        print $"(ansi red)Error: nu-protocol & nu-plugin versions do not match Nushell version(ansi reset)"
        print $"Current Nushell version: ($nushell_version)"
        print $"Plugin [($plugin_name)] nu-protocol version: ($cargo_toml.dependencies.nu-protocol)"
        print $"Plugin [($plugin_name)] nu-plugin version: ($cargo_toml.dependencies.nu-plugin)"

        let continue = (input "Continue with install with version override? [y/n]: ")
        if $continue != "y" {
            return
        }

        $cargo_toml.dependencies."nu-protocol" = $nushell_version
        $cargo_toml.dependencies."nu-plugin" = $nushell_version
        $cargo_toml | to toml | save -f $cargo_toml_path
    }

    ^cargo install --path .

    let home_directory = ("~" | path expand)
    let cargo_bin_directory = ($home_directory | path join ".cargo" "bin")
    mut plugin_binary_name = $"nu_plugin_($plugin_name)"
    if sys.host.name == "Windows" {
        $plugin_binary_name += ".exe"
    }
    let plugin_path = ($cargo_bin_directory | path join $plugin_binary_name)

    nu -c $"plugin add ($plugin_path)"
    let plugin_commands = (plugin list | where name == $plugin_name | first | get commands)

    print $"(ansi green)Plugin ($plugin_name) installed successfully!(ansi reset)"
    print $"Available commands: ($plugin_commands)"
}
''
