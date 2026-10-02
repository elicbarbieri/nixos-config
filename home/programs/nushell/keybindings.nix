''
# ++= (plain = wipes nushell's default bindings)
$env.config.keybindings ++= [
    {
        name: quick_cd
        modifier: control
        keycode: char_g
        mode: emacs
        event: {
            send: executehostcommand
            cmd: "cd (fd . -t d | fzf --height=50% --preview '^ls --color=always {}' | str trim)"
        }
    }
    {
        name: file_finder
        modifier: control
        keycode: char_f
        mode: emacs
        event: {
            send: executehostcommand
            cmd: "commandline edit --insert (fd . -t f | fzf --height=50% --preview '^bat --color=always {}' | str trim)"
        }
    }
    {
        name: open_in_explorer
        modifier: control
        keycode: char_o
        mode: emacs
        event: {
            send: executehostcommand
            cmd: "xdg-open ."
        }
    }
]
''
