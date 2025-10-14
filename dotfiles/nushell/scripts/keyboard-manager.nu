#!/usr/bin/env -S nu

# Simplified Keyboard Management System for keyd
# Architecture:
# - Hyprland config uses QWERTY logical positions (no changes needed)
# - keyd handles physical key remapping at kernel level
# - Toggle keyd on/off based on laptop vs external keyboard detection
# - NixOS manages /etc/keyd/default.conf configuration

# Check if system is a laptop
def is_laptop [] {
    try {
        let has_battery = ("/sys/class/power_supply" | path exists) and ((ls /sys/class/power_supply | where name =~ "BAT" | length) > 0)
        let has_lid = ("/proc/acpi/button/lid" | path exists)
        let is_portable = (try { open /sys/class/dmi/id/chassis_type | into int } catch { 0 }) in [8 9 10 11 14]
        
        $has_battery or $has_lid or $is_portable
    } catch {
        false
    }
}

# Check if external USB keyboard is connected
def has_usb_keyboard [] {
    try {
        let devices_content = (open --raw /proc/bus/input/devices)
        let device_blocks = ($devices_content | split row "\n\n" | where ($it | str trim) != "")
        
        let usb_keyboards = ($device_blocks | where {|block|
            let lines = ($block | split row '\n')
            let name_line = ($lines | where ($it | str starts-with "N: Name=") | first)
            let phys_line = ($lines | where ($it | str starts-with "P: Phys=") | first)
            let handlers_line = ($lines | where ($it | str starts-with "H: Handlers=") | first)
            
            # Check if it's a keyboard with USB physical connection
            let is_keyboard = ($handlers_line | str contains "kbd")
            let is_usb = ($phys_line | str contains "usb")
            
            $is_keyboard and $is_usb
        })
        
        ($usb_keyboards | length) > 0
    } catch {
        # Fallback: Check /dev/input/by-path/ for USB keyboards
        try {
            let usb_kbd_devices = (ls /dev/input/by-path/ | where name =~ "usb.*kbd$")
            ($usb_kbd_devices | length) > 0
        } catch {
            false
        }
    }
}

# Check if keyd is currently active
def keyd_status [] {
    try {
        let processes = (^pgrep keyd)
        if ($processes | str trim) != "" {
            "active"
        } else {
            "inactive"
        }
    } catch {
        "inactive"
    }
}
# Enable keyd
def enable_keyd [--silent (-s)] {
    try {
        ^sh -c "keyd >/dev/null 2>&1 &"

        if not $silent {
            ^notify-send "Keyboard Manager" "✅ keyd enabled (Colemak + nav layer active)" --urgency=normal
        }
    } catch { |e|
        if not $silent {
            ^notify-send "Keyboard Manager" $"❌ Failed to enable keyd: ($e.msg)" --urgency=critical
        }
    }
}

# Disable keyd
def disable_keyd [--silent (-s)] {
    try {
        ^pkill keyd
        if not $silent {
            ^notify-send "Keyboard Manager" "✅ keyd disabled (hardware/QMK layout active)" --urgency=normal
        }
    } catch { |e|
        if not $silent {
            ^notify-send "Keyboard Manager" $"❌ Failed to disable keyd: ($e.msg)" --urgency=critical
        }
    }
}

# Toggle keyd on/off based on current state
def toggle_keyboard [] {
    let current_status = (keyd_status)
    
    if $current_status == "active" {
        disable_keyd
    } else {
        enable_keyd
    }
}

# Startup detection and silent configuration
def startup_detect [] {
    let laptop = (is_laptop)
    let external_kb = (has_usb_keyboard)
    
    if $laptop and not $external_kb {
        enable_keyd --silent
    } else {
        disable_keyd --silent
    }
}

# Show current keyboard status
def status [] {
    let laptop = (is_laptop)
    let external_kb = (has_usb_keyboard)
    let keyd_active = (keyd_status)
    
    print "🔍 Keyboard Setup Status"
    print "======================="
    
    let system_type = if $laptop { "Laptop" } else { "Desktop" }
    print $"System Type: ($system_type)"
    
    let kb_status = if $external_kb { "Connected" } else { "Not detected" }
    print $"External USB Keyboard: ($kb_status)"
    
    print $"keyd Status: ($keyd_active)"
    print ""
    
    if $laptop and not $external_kb {
        print "🎯 Expected Mode: Laptop (keyd active for Colemak + nav layer)"
        let correct = ($keyd_active == "active")
        let status_msg = if $correct { "✅ Correct" } else { "❌ keyd should be active" }
        print $"Status: ($status_msg)"
    } else {
        print "⌨️ Expected Mode: External keyboard (keyd disabled for hardware layout)"
        let correct = ($keyd_active != "active")
        let status_msg = if $correct { "✅ Correct" } else { "❌ keyd should be disabled" }
        print $"Status: ($status_msg)"
    }
    print ""
    
    print "Config file:"
    let config_exists = ("/etc/keyd/default.conf" | path exists)
    let config_status = if $config_exists { "✅ Found" } else { "❌ Missing" }
    print $"  /etc/keyd/default.conf: ($config_status)"
}

# Main command dispatcher
def main [
    action?: string  # Action: 'startup-detect', 'toggle', 'status'
] {
    match $action {
        "startup-detect" => { startup_detect },
        "toggle" => { toggle_keyboard },
        "status" => { status },
        null => { status },
        _ => {
            print "🎹 Eli's Keyboard Manager for keyd"
            print "=================================="
            print ""
            print "Usage: kb <action>"
            print ""
            print "Actions:"
            print "  startup-detect     - Silent detection and setup (for exec-once)"
            print "  toggle             - Toggle keyd on/off with notifications"
            print "  status             - Show current keyboard detection status"
            print ""
            print "Note: Config is managed by NixOS at /etc/keyd/default.conf"
            print ""
            print "Hyprland Integration:"
            print "  exec-once = kb startup-detect"
        }
    }
}
