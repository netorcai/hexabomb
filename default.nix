{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/18.03.tar.gz") {}}:

with pkgs;

stdenv.mkDerivation rec {
  name = "hexabomb-${version}";
  version = "git";

  src = ./.;

  nativeBuildInputs = [ dmd dub ];
  doCheck = true;

  buildPhase = ''dub build --force'';
  checkPhase = ''dub test'';
  installPhase = ''
    mkdir -p $out/bin
    cp ./hexabomb $out/bin/
  '';
}
