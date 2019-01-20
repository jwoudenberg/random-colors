{ pkgs ? import ./pkgs.nix }:

pkgs.stdenv.mkDerivation rec {
  name = "random-colors-${version}";
  version = "0.1.0";
  depsBuildBuild = [ pkgs.nim ];
  src = ./src;
  buildPhase = ''
    nim compile \
      --nimcache:$TMPDIR \
      --out:$TMPDIR/random-colors \
      ${src}/random_colors.nim
  '';
  installPhase = ''
    install -Dt \
      $out/bin \
      $TMPDIR/random-colors
  '';

  meta = with pkgs.stdenv.lib; {
    description = "A tool generating random cli colorschemes for all projects and branches.";
    homepage = https://github.com/jwoudenberg/random-colorscheme;
    license = licenses.mit;
    platforms = with platforms; linux ++ darwin;
  };
}
