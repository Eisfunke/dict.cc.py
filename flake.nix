{
  description = "Unofficial dict.cc command line interface";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" ];

    perSystem = { pkgs, lib, ...}: let
      workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      pythonSet =
        (
          pkgs.callPackage inputs.pyproject-nix.build.packages { python = pkgs.python312; }
        ).overrideScope (
          lib.composeManyExtensions [
            inputs.pyproject-build-systems.overlays.default
            overlay
          ]
        );

    in {
      packages.default = pythonSet.mkVirtualEnv "dict.cc.py" workspace.deps.default;

      devShells.default = let
        virtualenv = pythonSet.mkVirtualEnv "dict.cc.py-dev" workspace.deps.all;
      in pkgs.mkShell {
        packages = [
          virtualenv
          pkgs.uv
        ];

        env = {
          UV_NO_SYNC = "1";  # don't create venv using uv
          UV_PYTHON = "${virtualenv}/bin/python";  # force uv to use Python interpreter from venv
          UV_PYTHON_DOWNLOADS = "never";  # prevent uv from downloading managed Python's
        };

        shellHook = ''
          # Undo dependency propagation by nixpkgs.
          unset PYTHONPATH

          # Get repository root using git. This is expanded at runtime by the editable `.pth` machinery.
          export REPO_ROOT=$(git rev-parse --show-toplevel)
        '';
      };
    };
  };
}
