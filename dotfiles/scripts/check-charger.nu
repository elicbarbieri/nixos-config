#!/usr/bin/env nu


def main [] {
    print "=== USB-C Power Delivery Status ==="
    print ""

    # Get all USB-C PD power supply ports
    let ports = (ls /sys/class/power_supply/ucsi-source-psy-* | get name)

    let active_ports = $ports | each { |port|
        let online = (open $"($port)/online" | str trim)

        if $online == "1" {
            let voltage_uv = (open $"($port)/voltage_now" | str trim | into int)
            let current_ua = (open $"($port)/current_max" | str trim | into int)

            let voltage_v = ($voltage_uv / 1_000_000.0)
            let current_a = ($current_ua / 1_000_000.0)
            let power_w = ($voltage_v * $current_a)

            {
                port: ($port | path basename)
                voltage: $voltage_v
                current: $current_a
                power: $power_w
                online: true
            }
        } else {
            null
        }
    } | compact

    if ($active_ports | length) > 0 {
        $active_ports | each { |port|
            print $"✓ ACTIVE: ($port.port)"
            print $"  Voltage: ($port.voltage | math round --precision 1)V"
            print $"  Current: ($port.current | math round --precision 2)A"
            print $"  Power:   ($port.power | math round --precision 1)W"
            print ""
        }
    } else {
        print "⚠ No active USB-C PD charger detected"
        print ""
    }

    print "=== Battery Status ==="
    let bat_status = (cat /sys/class/power_supply/BAT0/status | str trim)
    let bat_capacity = (cat /sys/class/power_supply/BAT0/capacity | str trim)
    
    # Try to read current_now, fall back to upower if it fails
    let bat_current_result = (^cat /sys/class/power_supply/BAT0/current_now | complete)
    
    if $bat_current_result.exit_code == 0 and ($bat_current_result.stdout | str trim | is-not-empty) {
        # sysfs method works
        let bat_voltage = (cat /sys/class/power_supply/BAT0/voltage_now | str trim | into int)
        let bat_current = ($bat_current_result.stdout | str trim | into int)
        
        let bat_voltage_v = ($bat_voltage / 1_000_000.0)
        let bat_current_a = ($bat_current / 1_000_000.0)
        let bat_power_w = ($bat_voltage_v * $bat_current_a)
        
        print $"Status:       ($bat_status)"
        print $"Charge:       ($bat_capacity)%"
        print $"Voltage:      ($bat_voltage_v | math round --precision 2)V"
        print $"Current:      ($bat_current_a | math round --precision 3)A"
        print $"Power Rate:   ($bat_power_w | math round --precision 1)W"
        
        # Calculate total system power consumption
        if ($active_ports | length) > 0 and $bat_status == "Charging" {
            let charger_power = ($active_ports | get power | math sum)
            let total_system_power = $charger_power - $bat_power_w
            print ""
            print $"Total System: ($total_system_power | math round --precision 1)W \(charger minus battery charging\)"
        } else if ($active_ports | length) > 0 and $bat_status == "Discharging" {
            let charger_power = ($active_ports | get power | math sum)
            let total_system_power = $charger_power + $bat_power_w
            print ""
            print $"Total System: ($total_system_power | math round --precision 1)W \(charger plus battery supplement\)"
            print "⚠ Warning: System power exceeds charger capacity!"
        }
    } else {
        # Fall back to upower
        let upower_output = (upower -i /org/freedesktop/UPower/devices/battery_BAT0 | lines)
        let energy_rate_line = ($upower_output | where $it =~ "energy-rate" | first | split row ":" | last | str trim)
        let energy_rate = ($energy_rate_line | split row " " | first | into float)
        
        print $"Status:       ($bat_status)"
        print $"Charge:       ($bat_capacity)%"
        
        if $energy_rate == 0 {
            print $"Power Rate:   Unknown \(battery sensor unavailable\)"
            print ""
            print "⚠ Battery current sensor not available"
            if ($active_ports | length) > 0 {
                let charger_power = ($active_ports | get power | math sum)
                print $"Note: System power ≈ ($charger_power | math round --precision 1)W when discharging \(estimate\)"
            }
        } else {
            print $"Power Rate:   ($energy_rate | math round --precision 1)W \(from upower\)"
            
            # Calculate total system power consumption
            if ($active_ports | length) > 0 and $bat_status == "Charging" {
                let charger_power = ($active_ports | get power | math sum)
                let total_system_power = $charger_power - $energy_rate
                print ""
                print $"Total System: ($total_system_power | math round --precision 1)W \(charger minus battery charging\)"
            } else if ($active_ports | length) > 0 and $bat_status == "Discharging" {
                let charger_power = ($active_ports | get power | math sum)
                let total_system_power = $charger_power + $energy_rate
                print ""
                print $"Total System: ($total_system_power | math round --precision 1)W \(charger plus battery supplement\)"
                print "⚠ Warning: System power exceeds charger capacity!"
            }
        }
    }
}
