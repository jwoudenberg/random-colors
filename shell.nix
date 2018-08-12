let
  fetch = { rev, sha256 }:
    builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
      sha256 = sha256;
    };

  pkgsPath = fetch {
    rev = "411cc559c052feb6e20a01fc6d5fa63cba09ce9a";
    sha256 = "158xky2p5lfdd5gb1v7rl7ss5k31r2hwazn97srfviivx25karaw";
  };

  pkgs = import pkgsPath { config = {}; };
in
pkgs.mkShell {
  buildInputs = [ pkgs.nim ];
}
