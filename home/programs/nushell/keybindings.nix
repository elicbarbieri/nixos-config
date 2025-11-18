{ ... }:

{
  keybindings = ''
    $env.config.keybindings = [
        # Shift+Enter for newline
        {
            name: insert_newline
            modifier: shift
            keycode: enter
            mode: [emacs, vi_insert]
            event: { edit: insertnewline }
        }
        
        # Enhanced completion menu
        {
            name: completion_menu
            modifier: none
            keycode: tab
            mode: [emacs, vi_insert]
            event: {
                until: [
                    { send: menu name: completion_menu }
                    { send: menunext }
                ]
            }
        }
        
        # Quick directory navigation with fzf
        {
            name: quick_cd
            modifier: control
            keycode: char_g
            mode: [emacs, vi_insert]
            event: {
                send: executehostcommand
                cmd: "cd (fd . -t d | fzf --height=50% --preview 'ls {}' | str trim)"
            }
        }
        
        # Open current directory in file manager
        {
            name: open_in_explorer
            modifier: control
            keycode: char_o
            mode: [emacs, vi_insert, vi_normal]
            event: {
                send: executehostcommand
                cmd: "xdg-open ."
            }
        }
    ]
    
    # Note: Atuin keybinding (Ctrl+R) is handled by programs.atuin.enableNushellIntegration
  '';
}
