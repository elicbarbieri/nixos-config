{ pkgs }:

let
  inherit (pkgs) lib;
  palette = import ./palette.nix;
  ansi = builtins.elemAt palette.ansi;

  # zjstatus top bar (session · tabs · mode chip; date = desktop shell's job)
  bar = ''
    pane size=2 borderless=true {
        plugin location="file:${pkgs.zjstatus}/bin/zjstatus.wasm" {
            format_left   "#[fg=${ansi 4}]  #[fg=${palette.foreground}]{session}"
            format_center "{tabs}"
            format_right  "{mode} "
            format_space  ""

            border_enabled  "true"
            border_char     "─"
            border_format   "#[fg=${ansi 8}]{char}"
            border_position "bottom"

            mode_locked "#[fg=${ansi 8}]"
            mode_normal "#[bg=${ansi 2},fg=${ansi 0},bold] {name} "
            mode_pane   "#[bg=${ansi 4},fg=${ansi 0},bold] {name} "
            mode_tab    "#[bg=${ansi 5},fg=${ansi 0},bold] {name} "
            mode_scroll "#[bg=${ansi 11},fg=${ansi 0},bold] {name} "
            mode_search "#[bg=${ansi 11},fg=${ansi 0},bold] {name} "
            mode_default_to_mode "normal"

            tab_normal "#[fg=${ansi 15}] {name}{fullscreen_indicator}{floating_indicator} "
            tab_active "#[bg=${ansi 0},fg=${palette.foreground},bold] {name}{fullscreen_indicator}{floating_indicator} "
            tab_fullscreen_indicator " 󰊓"
            tab_floating_indicator   " 󰉈"
        }
    }
  '';

  layout = pkgs.writeText "zjstatus.kdl" ''
    layout {
        default_tab_template {
            ${bar}
            children
        }
    }
  '';

  # zellij's own swap layouts w/ `ui` template (tab-bar + status-bar) → bar
  # - first block must stay `tab_template name="ui"` (fails build otherwise, not silent drift)
  layoutDir = pkgs.runCommand "zellij-layouts" { nativeBuildInputs = [ pkgs.zellij ]; } ''
    export HOME=$TMPDIR
    zellij setup --dump-swap-layout default > upstream.kdl
    if [ "$(head -n1 upstream.kdl)" != 'tab_template name="ui" {' ]; then
      echo "zellij default.swap.kdl no longer opens with the ui tab_template" >&2
      exit 1
    fi
    mkdir $out
    cp ${layout} $out/zjstatus.kdl
    {
      printf 'tab_template name="ui" {\n%s\nchildren\n}\n' ${lib.escapeShellArg bar}
      sed '1,/^}$/d' upstream.kdl
    } > $out/zjstatus.swap.kdl
  '';

  # `Ctrl b ?` → keymap parsed from the live config (no second copy to drift)
  zellijKeys = pkgs.writers.writePython3Bin "zellij-keys" {
    libraries = [ pkgs.python3Packages.kdl-py ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./zellij-keys.py);

  # Unlock-first preset (zellij presets.rs @ v0.45.1)
  # - prefix = Ctrl b (Alt = keyd nav layer, Super = Hyprland)
  # - secondary-modifier (Alt) block dropped
  zellijConfig = pkgs.writeText "config.kdl" ''
    // legacy palette: bg = selection / selected-row highlight (text_selected), not terminal bg
    themes {
        custom {
            fg "${palette.foreground}"
            bg "${ansi 8}"
            black "${ansi 0}"
            red "${ansi 1}"
            green "${ansi 2}"
            yellow "${ansi 3}"
            blue "${ansi 4}"
            magenta "${ansi 5}"
            cyan "${ansi 6}"
            white "${ansi 7}"
            orange "${ansi 11}"
        }
    }
    theme "custom"

    pane_frames false
    default_shell "nu"
    default_mode "locked"
    layout_dir "${layoutDir}"
    default_layout "zjstatus"

    keybinds clear-defaults=true {
        locked {
            bind "Ctrl b" { SwitchToMode "Normal"; }
        }
        normal {
            bind "h" { MoveFocusOrTab "Left"; SwitchToMode "Locked"; }
            bind "l" { MoveFocusOrTab "Right"; SwitchToMode "Locked"; }
            bind "j" { MoveFocus "Down"; SwitchToMode "Locked"; }
            bind "k" { MoveFocus "Up"; SwitchToMode "Locked"; }
            bind "n" { NewPane; SwitchToMode "Locked"; }
            bind "f" { ToggleFloatingPanes; SwitchToMode "Locked"; }
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
            bind "[" { PreviousSwapLayout; SwitchToMode "Locked"; }
            bind "]" { NextSwapLayout; SwitchToMode "Locked"; }
            bind "?" {
                Run "${zellijKeys}/bin/zellij-keys" {
                    floating true
                    close_on_exit true
                    name "zellij keys"
                };
                SwitchToMode "Locked"
            }
        }
        pane {
            bind "h" "Left" { MoveFocus "Left"; }
            bind "l" "Right" { MoveFocus "Right"; }
            bind "j" "Down" { MoveFocus "Down"; }
            bind "k" "Up" { MoveFocus "Up"; }
            bind "Tab" { SwitchFocus; }
            bind ";" { FocusLastPane; }
            bind "n" { NewPane; SwitchToMode "Locked"; }
            bind "d" { NewPane "Down"; SwitchToMode "Locked"; }
            bind "r" { NewPane "Right"; SwitchToMode "Locked"; }
            bind "s" { NewPane "stacked"; SwitchToMode "Locked"; }
            bind "x" { CloseFocus; SwitchToMode "Locked"; }
            bind "f" { ToggleFocusFullscreen; SwitchToMode "Locked"; }
            bind "Shift f" { ToggleFocusNoUiFullscreen; SwitchToMode "Locked"; }
            bind "z" { TogglePaneFrames; SwitchToMode "Locked"; }
            bind "w" { ToggleFloatingPanes; SwitchToMode "Locked"; }
            bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Locked"; }
            bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0; }
            bind "i" { TogglePanePinned; SwitchToMode "Locked"; }
            bind "p" { SwitchToMode "Normal"; }
        }
        tab {
            bind "h" "Left" "Up" "k" { GoToPreviousTab; }
            bind "l" "Right" "Down" "j" { GoToNextTab; }
            bind "Tab" { ToggleTab; }
            bind "n" { NewTab; SwitchToMode "Locked"; }
            bind "x" { CloseTab; SwitchToMode "Locked"; }
            bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
            bind "s" { ToggleActiveSyncTab; SwitchToMode "Locked"; }
            bind "b" { BreakPane; SwitchToMode "Locked"; }
            bind "[" { BreakPaneLeft; SwitchToMode "Locked"; }
            bind "]" { BreakPaneRight; SwitchToMode "Locked"; }
            bind "1" { GoToTab 1; SwitchToMode "Locked"; }
            bind "2" { GoToTab 2; SwitchToMode "Locked"; }
            bind "3" { GoToTab 3; SwitchToMode "Locked"; }
            bind "4" { GoToTab 4; SwitchToMode "Locked"; }
            bind "5" { GoToTab 5; SwitchToMode "Locked"; }
            bind "6" { GoToTab 6; SwitchToMode "Locked"; }
            bind "7" { GoToTab 7; SwitchToMode "Locked"; }
            bind "8" { GoToTab 8; SwitchToMode "Locked"; }
            bind "9" { GoToTab 9; SwitchToMode "Locked"; }
            bind "t" { SwitchToMode "Normal"; }
        }
        scroll {
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "PageUp" "Left" "h" { PageScrollUp; }
            bind "f" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "e" { EditScrollback; SwitchToMode "Locked"; }
            bind "[" { ScrollToPreviousPrompt; }
            bind "]" { ScrollToNextPrompt; }
            bind "m" { SelectCommandAtScrollPosition; }
            bind "c" { CopyLastCommandOutput; SwitchToMode "Locked"; }
            bind "Ctrl c" { ScrollToBottom; SwitchToMode "Locked"; }
            bind "s" { SwitchToMode "Normal"; }
        }
        entersearch {
            bind "Enter" { SwitchToMode "Search"; }
            bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
        }
        search {
            bind "n" { Search "down"; }
            bind "p" { Search "up"; }
            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "PageUp" "Left" "h" { PageScrollUp; }
            bind "[" { ScrollToPreviousPrompt; }
            bind "]" { ScrollToNextPrompt; }
            bind "m" { SelectCommandAtScrollPosition; }
            bind "Ctrl c" { ScrollToBottom; SwitchToMode "Locked"; }
        }
        session {
            bind "w" {
                LaunchOrFocusPlugin "session-manager" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Locked"
            }
            bind "d" { Detach; }
            bind "l" {
                LaunchOrFocusPlugin "zellij:layout-manager" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Locked"
            }
            bind "c" {
                LaunchOrFocusPlugin "configuration" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Locked"
            }
            bind "p" {
                LaunchOrFocusPlugin "plugin-manager" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Locked"
            }
            bind "s" {
                LaunchOrFocusPlugin "zellij:share" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Locked"
            }
            bind "a" {
                LaunchOrFocusPlugin "zellij:about" {
                    floating true
                    move_to_focused_tab true
                };
                SwitchToMode "Locked"
            }
            bind "[" { FocusGuestSession; SwitchToMode "Locked"; }
            bind "]" { FocusHostSession; SwitchToMode "Locked"; }
            bind "f" { ToggleHostFullscreen; SwitchToMode "Locked"; }
            bind "o" { SwitchToMode "Normal"; }
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
            bind "=" "+" { Resize "Increase"; }
            bind "-" { Resize "Decrease"; }
            bind "r" { SwitchToMode "Normal"; }
        }
        move {
            bind "h" "Left" { MovePane "Left"; }
            bind "j" "Down" { MovePane "Down"; }
            bind "k" "Up" { MovePane "Up"; }
            bind "l" "Right" { MovePane "Right"; }
            bind "n" "Tab" { MovePane; }
            bind "p" { MovePaneBackwards; }
            bind "m" { SwitchToMode "Normal"; }
        }
        renametab {
            bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
            bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
        }
        renamepane {
            bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
            bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
        }
        shared_except "locked" "renametab" "renamepane" {
            bind "Ctrl b" "Enter" { SwitchToMode "Locked"; }
            bind "Ctrl q" { Quit; }
        }
        shared_except "renamepane" "renametab" "entersearch" "locked" {
            bind "Esc" { SwitchToMode "Locked"; }
        }
        shared_except "pane" "locked" "renametab" "renamepane" "entersearch" {
            bind "p" { SwitchToMode "Pane"; }
        }
        shared_except "tab" "locked" "renametab" "renamepane" "entersearch" {
            bind "t" { SwitchToMode "Tab"; }
        }
        shared_except "scroll" "locked" "renametab" "renamepane" "entersearch" {
            bind "s" { SwitchToMode "Scroll"; }
        }
        shared_except "session" "locked" "renametab" "renamepane" "entersearch" {
            bind "o" { SwitchToMode "Session"; }
        }
        shared_except "resize" "locked" "renametab" "renamepane" "entersearch" {
            bind "r" { SwitchToMode "Resize"; }
        }
        shared_except "move" "locked" "renametab" "renamepane" "entersearch" {
            bind "m" { SwitchToMode "Move"; }
        }
    }
  '';

in
# ZELLIJ_CONFIG_FILE (not argv parsing) → explicit --config still wins
pkgs.writeTextFile {
  name = "zellij";
  destination = "/bin/zellij";
  executable = true;
  text = ''
    #!${pkgs.runtimeShell}
    export ZELLIJ_CONFIG_FILE="''${ZELLIJ_CONFIG_FILE:-${zellijConfig}}"
    exec ${pkgs.zellij}/bin/zellij "$@"
  '';
  # cheat sheet must render from this exact config → breakage at rebuild, not at Ctrl b ?
  checkPhase = "${zellijKeys}/bin/zellij-keys ${zellijConfig} > /dev/null";
}
