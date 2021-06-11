{
  description = "random-colors";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        random-colors = pkgs.callPackage ./default.nix { };
      in {
        defaultPackage = random-colors;
        devShell = pkgs.mkShell { buildInputs = [ pkgs.nim ]; };
      });
}
