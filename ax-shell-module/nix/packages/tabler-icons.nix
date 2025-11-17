{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "tabler-icons-font";
  version = "2024-08-31";

  src = fetchFromGitHub {
    owner = "Axenide";
    repo = "Ax-Shell";
    rev = "main";
    sha256 = "sha256-3C8XiGeAPci0H+9y7erL34bBbOiEmKTRpGErRkA/9oY=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype/tabler-icons
    cp assets/fonts/tabler-icons/tabler-icons.ttf $out/share/fonts/truetype/tabler-icons/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Tabler Icons font for ax-shell icon display";
    homepage = "https://github.com/Axenide/Ax-Shell";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
