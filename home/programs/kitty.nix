{ pkgs }:

let
  kittyConfig = pkgs.writeText "kitty.conf" ''
    # Catppuccin Mocha
    foreground              #CDD6F4
    background              #1E1E2E
    selection_foreground    #1E1E2E
    selection_background    #F5E0DC
    cursor                  #F5E0DC
    cursor_text_color       #1E1E2E
    url_color               #F5E0DC
    active_border_color     #B4BEFE
    inactive_border_color   #6C7086
    bell_border_color       #F9E2AF
    active_tab_foreground   #11111B
    active_tab_background   #CBA6F7
    inactive_tab_foreground #CDD6F4
    inactive_tab_background #181825
    tab_bar_background      #11111B
    mark1_foreground        #1E1E2E
    mark1_background        #B4BEFE
    mark2_foreground        #1E1E2E
    mark2_background        #CBA6F7
    mark3_foreground        #1E1E2E
    mark3_background        #74C7EC
    color0  #45475A
    color8  #585B70
    color1  #F38BA8
    color9  #F38BA8
    color2  #A6E3A1
    color10 #A6E3A1
    color3  #F9E2AF
    color11 #F9E2AF
    color4  #89B4FA
    color12 #89B4FA
    color5  #F5C2E7
    color13 #F5C2E7
    color6  #94E2D5
    color14 #94E2D5
    color7  #BAC2DE
    color15 #A6ADC8

    shell nu
    
    font_family      JetBrainsMono Nerd Font
    font_size        11
    bold_font        auto
    italic_font      auto
    bold_italic_font auto
    
    remember_window_size  no
    initial_window_width  1000
    initial_window_height 500
    window_padding_width  10
    hide_window_decorations yes
    confirm_os_window_close 0
    
    cursor_blink_interval 0.5
    cursor_stop_blinking_after 0
    
    scrollback_lines 10000
    scrollback_pager bat --paging=always --style=header-filename,changes --wrap=never
    
    enable_audio_bell no
    
    map ctrl+shift+plus  change_font_size all +1.0
    map ctrl+shift+minus change_font_size all -1.0
    
    map ctrl+left  resize_window narrower
    map ctrl+right resize_window wider
    map ctrl+up    resize_window taller
    map ctrl+down  resize_window shorter 3
    map ctrl+home  resize_window reset
    
    map ctrl+shift+h show_scrollback
    map ctrl+shift+f launch --type=overlay --stdin-source=@screen_scrollback fzf --no-sort --exact -i
  '';

in
pkgs.writeShellScriptBin "kitty" ''
  exec ${pkgs.kitty}/bin/kitty --config ${kittyConfig} "$@"
''
