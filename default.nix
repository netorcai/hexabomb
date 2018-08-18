let
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/18.03.tar.gz") {};
in

with pkgs;

stdenv.mkDerivation rec {
  name = "hexabomb-${version}";
  version = "git";

  src = ./.;

  nativeBuildInputs = [ dmd dub ];

  buildPhase = ''dub build --force'';
  installPhase = ''
    mkdir -p $out/bin
    cp ./hexabomb $out/bin/
  '';
}
