{ lib, pkgs }:

let
  # Override PyGObject to version 3.52.3 (matches your Ubuntu system) to fix typecode issues
  pygobject3-latest = pkgs.python3Packages.pygobject3.overridePythonAttrs (old: rec {
    version = "3.52.3";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/4a/36/fec530a313d3d48f12e112ac0a65ee3ccc87f385123a0493715609e8e99c/pygobject-3.52.3.tar.gz";
      sha256 = "00e427d291e957462a8fad659a9f9c8be776ff82a8b76bdf402f1eaeec086d82";
    };
  });

in pkgs.python3Packages.buildPythonPackage rec {
  pname = "fabric";
  version = "0.0.3";
  pyproject = true;  # Required for Python 3.13+

  src = pkgs.fetchFromGitHub {
    owner = "Fabric-Development";
    repo = "fabric";
    rev = "main";
    sha256 = "sha256-maDa5b+8/5tGJ3oCctd4xBuQlBNaMkLJZFbEXB3CtVU=";
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
