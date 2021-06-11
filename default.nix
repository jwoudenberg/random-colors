{ pkgs }:

pkgs.stdenv.mkDerivation rec {
  name = "random-colors-${version}";
  version = "0.1.0";
  depsBuildBuild = [ pkgs.nim ];
  buildInputs = [ pkgs.pcre ];
  src = ./src;
  buildPhase = ''
    nim compile \
      -d:release \
      --nimcache:$TMPDIR \
      --out:$TMPDIR/random-colors \
      ${src}/random_colors.nim
  '';
  installPhase = ''
    install -Dt \
      $out/bin \
      $TMPDIR/random-colors
  '';

  NIX_LDFLAGS = "-lpcre";

  meta = with pkgs.lib; {
    description =
      "A tool generating random cli colorschemes for all projects and branches.";
    homepage = "https://github.com/jwoudenberg/random-colorscheme";
    license = licenses.mit;
    platforms = with platforms; linux ++ darwin;
  };
}
