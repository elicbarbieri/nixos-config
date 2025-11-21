{ pkgs }:

let
  zellijConfig = pkgs.writeText "config.kdl" ''
    // Theme matching kitty colors
    themes {
        custom {
            fg "#e2e2e9"
            bg "#060709"
            black "#111318"
            red "#ffb2b9"
            green "#95d5a7"
            yellow "#b8cf84"
            blue "#adc6ff"
            magenta "#e4b7f3"
            cyan "#82d3e2"
            white "#e2e2e9"
            orange "#c3d696"
        }
    }

    // Use custom theme
    theme "custom"

    // Simplified UI
    simplified_ui true
    pane_frames false
    default_shell "nu"

    // Copy to system clipboard
    copy_command "wl-copy"
    copy_clipboard "system"

    // Mouse support
    mouse_mode true
    scroll_buffer_size 10000

    // Keybindings (vim-style with mod key as Ctrl)
    keybinds clear-defaults=true {
        normal {
            bind "Ctrl g" { SwitchToMode "locked"; }
            bind "Ctrl p" { SwitchToMode "pane"; }
            bind "Ctrl t" { SwitchToMode "tab"; }
            bind "Ctrl n" { SwitchToMode "resize"; }
            bind "Ctrl s" { SwitchToMode "scroll"; }
            bind "Ctrl o" { SwitchToMode "session"; }
            bind "Ctrl h" { MoveFocusOrTab "Left"; }
            bind "Ctrl l" { MoveFocusOrTab "Right"; }
            bind "Ctrl j" { MoveFocus "Down"; }
            bind "Ctrl k" { MoveFocus "Up"; }
            bind "Ctrl q" { Quit; }
        }
        
        locked {
            bind "Ctrl g" { SwitchToMode "normal"; }
        }
        
        pane {
            bind "h" "Left" { MoveFocus "Left"; }
            bind "l" "Right" { MoveFocus "Right"; }
            bind "j" "Down" { MoveFocus "Down"; }
            bind "k" "Up" { MoveFocus "Up"; }
            bind "n" { NewPane; SwitchToMode "normal"; }
            bind "d" { NewPane "Down"; SwitchToMode "normal"; }
            bind "r" { NewPane "Right"; SwitchToMode "normal"; }
            bind "x" { CloseFocus; SwitchToMode "normal"; }
            bind "f" { ToggleFocusFullscreen; SwitchToMode "normal"; }
            bind "z" { TogglePaneFrames; SwitchToMode "normal"; }
            bind "w" { ToggleFloatingPanes; SwitchToMode "normal"; }
            bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "normal"; }
            bind "Esc" { SwitchToMode "normal"; }
            bind "Ctrl p" { SwitchToMode "normal"; }
        }
        
        tab {
            bind "h" "Left" { GoToPreviousTab; }
            bind "l" "Right" { GoToNextTab; }
            bind "n" { NewTab; SwitchToMode "normal"; }
            bind "x" { CloseTab; SwitchToMode "normal"; }
            bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
            bind "s" { ToggleActiveSyncTab; SwitchToMode "normal"; }
            bind "1" { GoToTab 1; SwitchToMode "normal"; }
            bind "2" { GoToTab 2; SwitchToMode "normal"; }
            bind "3" { GoToTab 3; SwitchToMode "normal"; }
            bind "4" { GoToTab 4; SwitchToMode "normal"; }
            bind "5" { GoToTab 5; SwitchToMode "normal"; }
            bind "6" { GoToTab 6; SwitchToMode "normal"; }
            bind "7" { GoToTab 7; SwitchToMode "normal"; }
            bind "8" { GoToTab 8; SwitchToMode "normal"; }
            bind "9" { GoToTab 9; SwitchToMode "normal"; }
            bind "Tab" { ToggleTab; }
            bind "Esc" { SwitchToMode "normal"; }
            bind "Ctrl t" { SwitchToMode "normal"; }
        }
        
        resize {
            bind "h" "Left" { Resize "Increase Left"; }
            bind "j" "Down" { Resize "Increase Down"; }
            bind "k" "Up" { Resize "Increase Up"; }
            bind "l" "Right" { Resize "Increase Right"; }
            bind "H" { Resize "Decrease Left"; }
            bind "J" { Resize "Decrease Down"; }
            bind "K" { Resize "Decrease Up"; }
            bind "L" { Resize "Decrease Right"; }
            bind "=" { Resize "Increase"; }
            bind "-" { Resize "Decrease"; }
            bind "Esc" { SwitchToMode "normal"; }
            bind "Ctrl n" { SwitchToMode "normal"; }
        }
        
        scroll {
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Ctrl f" "PageDown" { PageScrollDown; }
            bind "Ctrl b" "PageUp" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "s" { SwitchToMode "entersearch"; SearchInput 0; }
            bind "Esc" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Ctrl s" { SwitchToMode "normal"; }
        }
        
        search {
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Ctrl f" "PageDown" { PageScrollDown; }
            bind "Ctrl b" "PageUp" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "n" { Search "down"; }
            bind "N" { Search "up"; }
            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }
            bind "Esc" { ScrollToBottom; SwitchToMode "normal"; }
            bind "Ctrl s" { ScrollToBottom; SwitchToMode "normal"; }
        }
        
        entersearch {
            bind "Ctrl c" "Esc" { SwitchToMode "scroll"; }
            bind "Enter" { SwitchToMode "search"; }
        }
        
        renametab {
            bind "Esc" { UndoRenameTab; SwitchToMode "tab"; }
            bind "Ctrl c" { SwitchToMode "normal"; }
        }
        
        renamepane {
            bind "Esc" { UndoRenamePane; SwitchToMode "pane"; }
            bind "Ctrl c" { SwitchToMode "normal"; }
        }
        
        session {
            bind "d" { Detach; }
            bind "w" {
                LaunchOrFocusPlugin "session-manager" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "normal"
            }
            bind "Esc" { SwitchToMode "normal"; }
            bind "Ctrl o" { SwitchToMode "normal"; }
        }
    }

    // UI configuration
    ui {
        pane_frames {
            rounded_corners true
        }
    }

    // Session options
    session_serialization false
    pane_viewport_serialization false
    scrollback_lines_to_serialize 0
  '';

in
pkgs.writeShellScriptBin "zellij" ''
  exec ${pkgs.zellij}/bin/zellij --config ${zellijConfig} "$@"
''
