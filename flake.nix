{
  description = "Unofficial dict.cc command line interface";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
  };

  outputs = inputs@{ flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;
    perSystem = { self', pkgs, ... }: let
      poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
    in {
      packages.default = poetry2nix.mkPoetryApplication {
        projectDir = inputs.self;
      };
      devShells.default = pkgs.mkShellNoCC {
        inputsFrom = [ self'.packages.default ];
        packages = [ pkgs.poetry ];
      };
    };
  };
}
