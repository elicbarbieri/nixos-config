# Prebuilt simplex-chat CLI binary from GitHub releases
# Using the prebuilt binary avoids haskell.nix / GHC compilation (multi-hour build)
# To update: change version + re-run nix-prefetch-url for the new binary
{ stdenv, fetchurl, autoPatchelfHook, glibc, zlib, openssl, gmp }:

stdenv.mkDerivation rec {
  pname = "simplex-chat";
  version = "6.4.8";

  src = fetchurl {
    url = "https://github.com/simplex-chat/simplex-chat/releases/download/v${version}/simplex-chat-ubuntu-22_04-x86_64";
    hash = "sha256-rWhkPgx8EA0uMpGbFJsA+QbmWus9wpy0T2kavDsBWpg=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ glibc zlib openssl gmp ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    install -Dm755 $src $out/bin/simplex-chat
  '';

  meta = {
    description = "SimpleX Chat CLI — private messaging without user identifiers";
    homepage = "https://simplex.chat";
    mainProgram = "simplex-chat";
  };
}
