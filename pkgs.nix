let
  fetch = { rev, sha256 }:
    builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
      sha256 = sha256;
    };

  pkgsPath = fetch {
    rev = "0b471f71fada5f1d9bb31037a5dfb1faa83134ba";
    sha256 = "148vh3602ckm1vbqgs07fxwpdla62h37wspgy0bkcycqdavh7ra5";
  };
in
import pkgsPath { config = {}; }
