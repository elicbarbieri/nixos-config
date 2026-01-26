{ lib
, python3Packages
, fetchFromGitHub
, callPackage
, wrapGAppsHook3
, gobject-introspection
, pkg-config
, gtk3
, glib
, cairo
, gdk-pixbuf
, pango
, libdbusmenu-gtk3
, gtk-layer-shell
, gnome-bluetooth
, cinnamon-desktop
, vte
, networkmanager
, upower
, wayland
, wayland-protocols
, webp-pixbuf-loader
, brightnessctl
, cliphist
, hyprshot
, playerctl
, cava
, libnotify
, dbus
, dbus-glib
, imagemagick
, wl-clipboard
, procps
, swww
, matugen
, bibata-cursors
, makeDesktopItem
# Module configuration passed from NixOS module
, moduleConfig ? null
, ax-shell-lib ? null
, username ? null
}:

python3Packages.buildPythonApplication rec {
  pname = "ax-shell";
  version = "v0.0.63";
  format = "other";

  src = fetchFromGitHub {
    owner = "elicbarbieri";
    repo = "ax-shell";
    rev = "321b6ec8b1c3314db16e30df93d58129b1292eab";
    sha256 = "sha256-e4vdbDMtfpXNpZrcXX/53J1oHqa8ZA2o24sPpWLx0IQ=";
  };

  # Core Python dependencies
  propagatedBuildInputs = with python3Packages; [
    pycairo dbus-python
    loguru psutil click
    ijson numpy pillow pywayland requests setproctitle toml watchdog
    (callPackage ./python-fabric.nix {})
  ];

  nativeBuildInputs = [
    wrapGAppsHook3  # Critical for proper GObject wrapping
    gobject-introspection
    pkg-config  # Required for finding system libraries
  ];

  buildInputs = [
    gtk3 glib cairo gdk-pixbuf pango libdbusmenu-gtk3 gtk-layer-shell
    gnome-bluetooth cinnamon-desktop vte
    networkmanager
    upower
    wayland wayland-protocols
    webp-pixbuf-loader
    dbus dbus-glib
    brightnessctl cliphist hyprshot playerctl libnotify cava
    imagemagick wl-clipboard procps swww matugen
    bibata-cursors
    (callPackage ./fabric-cli.nix {})
    (callPackage ./gray.nix {})
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ax-shell
    cp -r * $out/lib/ax-shell/

    # Generate NixOS module configs directly in the nix store
    mkdir -p $out/lib/ax-shell/config
    mkdir -p $out/lib/ax-shell/styles

    ${lib.optionalString (moduleConfig != null && ax-shell-lib != null) ''
      # Generate config.json from NixOS module configuration
      cat > $out/lib/ax-shell/config/config.json << 'EOF'
      ${ax-shell-lib.generateConfigFile moduleConfig}
      EOF
    ''}

    # Patch ax-shell to use matugen_state file instead of matugen directory
    # This avoids collision: config/matugen/ is a directory (templates), matugen_state is a file (toggle state)
    substituteInPlace $out/lib/ax-shell/config/data.py \
      --replace-fail 'MATUGEN_STATE_FILE = os.path.join(CONFIG_DIR, "matugen")' \
                     'MATUGEN_STATE_FILE = os.path.join(CONFIG_DIR, "matugen_state")'

    # Patch settings_utils.py to use nix store paths for assets (not wallpapers)
    # 1. Fix default face icon path (~/.face.icon fallback) - use relative path from config/ dir
    substituteInPlace $out/lib/ax-shell/config/settings_utils.py \
      --replace-fail 'default_icon_path = os.path.expanduser(
        f"~/.config/{APP_NAME_CAP}/assets/default.png"
    )' \
                     'default_icon_path = os.path.join(os.path.dirname(__file__), "..", "assets", "default.png")'

    # 2. Fix notification icon (ax.png) in generated hyprland config - use nix store path
    substituteInPlace $out/lib/ax-shell/config/settings_utils.py \
      --replace-fail '"{home}/.config/{APP_NAME_CAP}/assets/ax.png"' \
                     '"'$out'/lib/ax-shell/assets/ax.png"'

    # Patch main.py to make app accessible at module level for fabric-cli exec
    # 1. Add module-level app variable declaration after imports
    sed -i '/^fonts_updated_file = f"{CACHE_DIR}\/fonts_updated"$/a\
\
# Module-level app variable for fabric-cli exec access\
app = None' $out/lib/ax-shell/main.py

    # 2. Remove the 'global app' line if it exists (from previous patch attempt)
    sed -i '/^    global app$/d' $out/lib/ax-shell/main.py

    # Patch main.css to import colors.css from user's home directory
    ${lib.optionalString (username != null) ''
      substituteInPlace $out/lib/ax-shell/main.css \
        --replace-fail '@import url("./styles/colors.css");' \
                       '@import url("/home/${username}/.config/Ax-Shell/styles/colors.css");'
    ''}

    # Create wayland session file
    mkdir -p $out/share/wayland-sessions
    cat > $out/share/wayland-sessions/ax-shell.desktop << EOF
[Desktop Entry]
Name=Ax-Shell
Comment=Modern desktop shell for Wayland
Exec=ax-shell
Type=Application
DesktopNames=Ax-Shell
EOF

    # Back to the original working Python wrapper with runtime setup
    mkdir -p $out/bin
    cat > $out/bin/ax-shell << 'EOF'
#!/usr/bin/env python3
import sys
import os
from pathlib import Path

ax_shell_dir = os.path.join(os.path.dirname(__file__), '../lib/ax-shell')
os.chdir(ax_shell_dir)

sys.path.insert(0, ax_shell_dir)

# Execute main.py with correct __file__ context
# Use actual globals (not a copy) so fabric-cli exec can access variables like 'app'
exec_globals = globals()
exec_globals['__file__'] = os.path.join(ax_shell_dir, 'main.py')
exec(open('main.py').read(), exec_globals)
EOF
    chmod +x $out/bin/ax-shell

    runHook postInstall
  '';

  # Ensure proper GI path and Python path
  preFixup = ''
    makeWrapperArgs+=(
      --prefix PYTHONPATH : "$out/lib/ax-shell"
      --prefix PATH : "${lib.makeBinPath [ cava brightnessctl cliphist hyprshot playerctl imagemagick wl-clipboard procps swww matugen ]}"
      --set WAYLAND_DISPLAY "wayland-1"
      --set GDK_BACKEND "wayland"
      --set XDG_CURRENT_DESKTOP "Hyprland"
      --set XCURSOR_THEME "Bibata-Modern-Classic"
      --set XCURSOR_PATH "${bibata-cursors}/share/icons"
    )
  '';

  # Create desktop session entry
  desktopItems = [
    (makeDesktopItem {
      name = "ax-shell";
      desktopName = "Ax-Shell";
      comment = "Modern desktop shell for Wayland";
      exec = "ax-shell";
      icon = "ax-shell";
      type = "Application";
      categories = [ "System" "Core" ];
      keywords = [ "desktop" "shell" "wayland" "compositor" ];
    })
  ];

  passthru = {
    providedSessions = [ "ax-shell" ];
  };

  meta = with lib; {
    description = "Modern desktop shell for Wayland compositors with customizable widgets and theming";
    longDescription = ''
      Ax-Shell is a comprehensive desktop environment built for Wayland compositors,
      featuring customizable widgets, theming support, and modern design principles.
      It provides a complete desktop experience with panel, dock, launcher, and
      system management capabilities.
    '';
    homepage = "https://github.com/elicbarbieri/ax-shell";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ /* add your maintainer info here */ ];
    mainProgram = "ax-shell";
  };
}
