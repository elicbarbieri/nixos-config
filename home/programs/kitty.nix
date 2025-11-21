{ pkgs }:

let
  kittyColors = pkgs.writeText "colors.conf" ''
    cursor #e2e2e9
    cursor_text_color #c4c6d0
    
    foreground            #e2e2e9
    background            #060709
    selection_foreground  #293041
    selection_background  #bfc6dc
    url_color             #adc6ff
    
    # black
    color8   #37393e
    color0   #111318
    
    # red
    color9 #ffccd0
    color1 #ffb2b9
    
    # green
    color10 #a7dcb6
    color2 #95d5a7
    
    # yellow
    color11 #c3d696
    color3 #b8cf84
    
    # blue
    color12 #d0d9ff
    color4  #adc6ff
    
    # magenta
    color13 #eccdf7
    color5 #e4b7f3
    
    # cyan
    color14 #97dae7
    color6 #82d3e2
    
    # white
    color7 #e2e2e9
    color15 #c4c6d0
  '';

  kittyConfig = pkgs.writeText "kitty.conf" ''
    include ${kittyColors}

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
