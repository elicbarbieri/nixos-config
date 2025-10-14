#!/usr/bin/env -S nu

# Nushell startup debugging script
print "=== Nushell Startup Debug ==="

# Check nushell version and installation
print $"\n🔧 Nushell Information:"
print $"Version: (version)"
print $"Executable: (which nu)"
print $"Config path: ($nu.config-path)"
print $"Home path: ($nu.home-path)"

# Check configuration files
let config_files = [
    $"($nu.config-path)/config.nu"
    $"($nu.config-path)/env.nu"  
    $"($nu.home-path)/.cargo/env.nu"
    $"($nu.home-path)/.cargo/env"
]

print "\n📁 Configuration Files:"
for file in $config_files {
    if ($file | path exists) {
        let size = (ls $file | get size | first)
        print $"✓ ($file) - ($size) bytes"
        
        # Check for BOM or other issues
        try {
            let content = (open --raw $file)
            if ($content | str starts-with "\ufeff") {
                print $"  ⚠ BOM detected in ($file)"
            }
        } catch { |err|
            print $"  ❌ Cannot read ($file): ($err.msg)"
        }
    } else {
        print $"❌ ($file) - not found"
    }
}

# Check cargo setup
print "\n📦 Cargo Information:"
try {
    let cargo_which = (which cargo)
    if ($cargo_which | is-empty) {
        print "❌ Cargo not found in PATH"
    } else {
        print $"✓ Cargo found: ($cargo_which.0.path)"
        try {
            let version = (^cargo --version)
            print $"✓ Version: ($version)"
        } catch { |err|
            print $"❌ Cargo version check failed: ($err.msg)"
        }
    }
} catch { |err|
    print $"❌ Cargo check failed: ($err.msg)"
}

# Check for PATH conflicts
print "\n⚠ PATH Analysis:"
let path_entries = ($env.PATH | where ($it | str contains "cargo" or $it | str contains "nix" or $it | str contains "brew"))
if ($path_entries | is-empty) {
    print "No cargo/nix/brew entries found in PATH"
} else {
    for entry in $path_entries {
        print $"  - ($entry)"
    }
}

# Test minimal functionality
print "\n✅ Basic Functionality Test:"
try {
    let test = (2 + 2)
    print $"Math: 2 + 2 = ($test)"
    
    let test_list = [1 2 3] | length
    print $"Lists: [1 2 3] length = ($test_list)"
    
    print "✅ Basic nushell functionality works"
} catch { |err|
    print $"❌ Basic functionality failed: ($err.msg)"
}

print "\n=== Debug Complete ===