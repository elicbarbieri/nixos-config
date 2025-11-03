{ lib, pkgs }:

let
  # Fetch pythoncapi-compat subproject that pygobject 3.54.5 requires
  pythoncapi-compat = pkgs.fetchFromGitHub {
    owner = "python";
    repo = "pythoncapi-compat";
    rev = "632d1aa0c4be6c67498d6b97630ddd7d7eb0f90a";
    sha256 = "1xazggp4fxi5xvgcgb8373ijs9xyfzi4id6r0i83wn6anh475xnc";
  };

  # Override PyGObject to use version 3.54.5 from the official GNOME repository
  pygobject3-latest = pkgs.python3Packages.pygobject3.overridePythonAttrs (old: rec {
    version = "3.54.5";
    src = pkgs.fetchFromGitHub {
      owner = "GNOME";
      repo = "pygobject";
      rev = version;
      sha256 = "0v068rpp6bd2mvm426azz07g8jis0762m844b85nnfv4hpmr18v2";
    };
    
    # Disable tests to avoid needing gobject-introspection-tests subproject
    mesonFlags = (old.mesonFlags or []) ++ [ "-Dtests=false" ];
    
    # Provide the pythoncapi-compat subproject that Meson expects
    postPatch = (old.postPatch or "") + ''
      mkdir -p subprojects/pythoncapi-compat
      cp -r ${pythoncapi-compat}/* subprojects/pythoncapi-compat/
      # Apply the meson.build patch that pygobject provides for pythoncapi-compat
      cat > subprojects/pythoncapi-compat/meson.build << 'EOF'
project(
  'pythoncapi-compat',
  'c'
)

incdir = include_directories('.')
EOF
    '';
  });

in pkgs.python3Packages.buildPythonPackage rec {
  pname = "fabric";
  version = "0.0.3";
  pyproject = true;  # Required for Python 3.13+

  src = pkgs.fetchFromGitHub {
    owner = "Fabric-Development";
    repo = "fabric";
    rev = "main";
    sha256 = "sha256-ELXYed743Xnad8hOMmN5RI0S8w0rltcZbylQjjFiv6s=";
  };

  # Patch pyproject.toml to accept PyGObject 3.52.3 instead of strict 3.50.0 pin
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'PyGObject==3.50.0' 'PyGObject>=3.50.0'
    substituteInPlace requirements.txt \
      --replace-fail 'PyGObject==3.50.0' 'PyGObject>=3.50.0'
  '';

  build-system = with pkgs.python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with pkgs.python3Packages; [
    click
    loguru
    pycairo
    pygobject3-latest  # Use our overridden version
    psutil
  ];

  nativeBuildInputs = with pkgs; [
    pkg-config
    gobject-introspection
    wrapGAppsHook3
  ];

  buildInputs = with pkgs; [
    glib
    gtk3
    cairo
    gdk-pixbuf
    gtk-layer-shell
    libdbusmenu-gtk3
    gnome-bluetooth
    cinnamon-desktop
    networkmanager  # For NM GI typelibs
    gobject-introspection
  ];

  pythonImportsCheck = [ "fabric" ];

  meta = with pkgs.lib; {
    description = "Next-Gen python framework for creating system widgets on *Nix systems!";
    homepage = "https://github.com/Fabric-Development/fabric";
    license = licenses.agpl3Plus;
    platforms = platforms.linux;
  };
}
