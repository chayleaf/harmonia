{
  description = "Nix binary cache implemented in rust using libnix-store";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts";
    inputs.nixpkgs-lib.follows = "nixpkgs";
  };
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

  nixConfig.extra-substituters = [
    "https://cache.garnix.io"
  ];

  nixConfig.extra-trusted-public-keys = [
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
  ];

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      perSystem = { lib, config, pkgs, ... }: {
        packages.harmonia = pkgs.callPackage ./. { };
        packages.default = config.packages.harmonia;
        checks = (import ./tests/default.nix {
          inherit pkgs;
          inherit (inputs) self;
        }) // {
          clippy = config.packages.harmonia.override ({
            enableClippy = true;
          });
        };
        devShells.default = pkgs.callPackage ./shell.nix { };

        treefmt = {
          # Used to find the project root
          projectRootFile = "flake.lock";

          programs.rustfmt.enable = true;

          settings.formatter = {
            nix = {
              command = "sh";
              options = [
                "-eucx"
                ''
                  export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.findutils pkgs.deadnix pkgs.nixpkgs-fmt ]}
                  deadnix --edit "$@"
                  nixpkgs-fmt "$@"
                ''
                "--"
              ];
              includes = [ "*.nix" ];
            };
          };
        };
      };
      flake.nixosModules.harmonia = ./module.nix;
    };
}
