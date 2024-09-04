{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    googletest = {
      url = "git+https://github.com/google/googletest";
      flake = false;
    };
  };

  outputs = { nixpkgs, googletest, ... }: let
    project = system: nixpkgs.legacyPackages.${system}.callPackage ./default.nix {
      inherit googletest;
    };
  in {
    packages."x86_64-linux".default = project "x86_64-linux";
  };
}
