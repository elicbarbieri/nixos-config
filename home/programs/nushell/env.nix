''
$env.PATH = $env.PATH | prepend [
    $"($env.HOME)/.cache/.bun/bin"
    $"($env.HOME)/.local/bin"
    $"($env.HOME)/.cargo/bin"
]
''
