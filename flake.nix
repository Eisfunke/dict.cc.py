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
    perSystem = { inputs', pkgs, ... }: let
      poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
    in {

      packages.default = poetry2nix.mkPoetryApplication {
        projectDir = inputs.self;
        groups = [ ];
        checkGroups = [ ];
      };

      devShells.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.poetry
          (poetry2nix.mkPoetryEnv {
            projectDir = inputs.self;
            preferWheels = true;  # don't build locally to save time
          })
        ];
      };

    };
  };
}
