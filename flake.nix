{
  description = "TacMetrics, collection of metrics to measure tactical game play style";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      python = pkgs.python313;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
        nixpkgs.lib.composeManyExtensions [
          pyproject-build-systems.overlays.default
          overlay
        ]
      );

      editableOverlay = workspace.mkEditablePyprojectOverlay { root = "$REPO_ROOT"; };

      devPythonSet = pythonSet.overrideScope (nixpkgs.lib.composeManyExtensions [ editableOverlay ]);

      virtualenv = devPythonSet.mkVirtualEnv "dev-env" workspace.deps.all;

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          virtualenv
          pkgs.uv
          pkgs.julia-bin # ✅ Add Julia
        ];

        env = {
          UV_NO_SYNC = "1";
          UV_PYTHON = python.interpreter;
          UV_PYTHON_DOWNLOADS = "never";
        };

        shellHook = ''
          unset PYTHONPATH
          export REPO_ROOT=$(git rev-parse --show-toplevel)
          rj() {
            # Check if Project.toml and Manifest.toml exist in the current directory
            if [[ -f "Project.toml" && -f "Manifest.toml" ]]; then
              # If they exist, execute Julia with the project flag
              echo "Activating project environment..."
              julia --project=. "$@"
            else
              # Otherwise, execute Julia normally
              echo "Running Julia in global environment..."
              julia "$@"
            fi
          }
        '';
      };
    };
}
