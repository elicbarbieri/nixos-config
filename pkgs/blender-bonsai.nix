# Blender with Bonsai BIM addon 0.8.4 (includes ifcopenshell 0.8.4)
#
# Approach:
# 1. Fetch pre-built Bonsai addon zip (bundles ifcopenshell + deps as wheels)
# 2. Unpack wheels into site-packages, patch native .so files for NixOS
# 3. Strip wheel references from blender_manifest.toml (deps already on PYTHONPATH)
# 4. Merge extension into Blender's system extensions dir via symlinkJoin
#
# To update: change version, update the fetchurl hash (build once with lib.fakeHash to get it)
{ pkgs }:

let
  blender = pkgs.blender;
  pythonVersion = "311";
  pythonDotVersion = "3.11";

  # Bonsai's bundled pyradiance links against libtiff.so.5 (soname from libtiff <= 4.4.0)
  # nixpkgs ships libtiff 4.7.x which provides .so.6 — build 4.4.0 from source for compat
  libtiff5 = pkgs.stdenv.mkDerivation rec {
    pname = "libtiff";
    version = "4.4.0";

    src = pkgs.fetchFromGitLab {
      owner = "libtiff";
      repo = "libtiff";
      rev = "v${version}";
      hash = "sha256-VfC2HeQU49v8QuxjvABtRBEud898WDCMPC11Jo/GuI8=";
    };

    nativeBuildInputs = with pkgs; [ cmake pkg-config ];
    buildInputs = with pkgs; [ libjpeg xz zlib zstd ];

    # Only need the shared lib output — skip docs, tests, tools
    cmakeFlags = [
      "-Dtiff-docs=OFF"
      "-Dtiff-tests=OFF"
      "-Dtiff-tools=OFF"
      "-Dtiff-contrib=OFF"
    ];

    meta.description = "libtiff 4.4.0 (provides libtiff.so.5 for legacy binary compat)";
  };

  bonsaiAddon = pkgs.stdenv.mkDerivation {
    pname = "bonsai-addon";
    version = "0.8.4";

    src = pkgs.fetchurl {
      url = "https://github.com/IfcOpenShell/IfcOpenShell/releases/download/bonsai-0.8.4/bonsai_py${pythonVersion}-0.8.4-linux-x64.zip";
      # Build once with lib.fakeHash to get the real hash from the error message
      hash = "sha256-FJTwQBfBvNPAaG2DoyPCBeUkCu7llxZKwYfRKQ3xxdw=";
    };

    sourceRoot = ".";

    nativeBuildInputs = with pkgs; [
      unzip
      autoPatchelfHook
      python311
    ];

    # Native libs required by bundled .so files (ifcopenshell, lxml, etc.)
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib # libstdc++
      zlib
      libxml2
      libxslt
      opencascade-occt
      boost
      hdf5
      gmp
      icu
      libtiff5
      libx11
      libxmu
      libxi
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # Install addon files into extensions layout
      mkdir -p $out/extensions
      cp -r bonsai $out/extensions/

      # Unpack all bundled wheels into a site-packages tree
      mkdir -p $out/lib/python${pythonDotVersion}/site-packages
      for wheel in $out/extensions/bonsai/wheels/*.whl; do
        ${pkgs.python311}/bin/python3 -m zipfile -e "$wheel" \
          $out/lib/python${pythonDotVersion}/site-packages/
      done

      # Remove wheels dir — deps now live in site-packages and get patched by autoPatchelfHook
      rm -rf $out/extensions/bonsai/wheels

      # Strip wheel declarations from manifest so Blender doesn't try to reinstall them
      ${pkgs.python311}/bin/python3 ${pkgs.writeText "strip-wheels.py" ''
        import re, pathlib, sys
        manifest = pathlib.Path(sys.argv[1])
        text = manifest.read_text()
        text = re.sub(r'\nwheels\s*=\s*\[.*?\]', "", text, flags=re.DOTALL)
        manifest.write_text(text)
      ''} $out/extensions/bonsai/blender_manifest.toml

      runHook postInstall
    '';

    meta = {
      description = "Bonsai BIM addon for Blender — open-source OpenBIM authoring platform";
      homepage = "https://bonsaibim.org";
    };
  };

in
pkgs.symlinkJoin {
  name = "blender-with-bonsai-${bonsaiAddon.version}";
  paths = [ blender ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    # Find Blender's version directory (e.g. "5.0")
    blenderVersion=$(ls ${blender}/share/blender/)

    # Replace the extensions symlink with a real directory merging original + bonsai
    rm -rf $out/share/blender/$blenderVersion/extensions
    mkdir -p $out/share/blender/$blenderVersion/extensions

    # Preserve existing system extensions
    if [ -d "${blender}/share/blender/$blenderVersion/extensions" ]; then
      for ext in ${blender}/share/blender/$blenderVersion/extensions/*; do
        ln -sf "$ext" "$out/share/blender/$blenderVersion/extensions/"
      done
    fi

    # Add Bonsai into the system extensions dir
    ln -sf ${bonsaiAddon}/extensions/bonsai \
      $out/share/blender/$blenderVersion/extensions/bonsai

    # Wrap blender binary to inject the unpacked wheel deps into Python path
    wrapProgram $out/bin/blender \
      --prefix PYTHONPATH : "${bonsaiAddon}/lib/python${pythonDotVersion}/site-packages"
  '';

  meta = blender.meta // {
    description = "Blender with Bonsai BIM ${bonsaiAddon.version}";
  };
}
