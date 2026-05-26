{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      nix-claude-code,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          rust-overlay.overlays.default
        ];
        pkgs = import nixpkgs { inherit system overlays; };
      in
      {
        devShells.default =
          with pkgs;
          mkShell {
            nativeBuildInputs = [
              bashInteractive
              (rust-bin.nightly."2026-04-16".default.override {
                extensions = [ "rust-src" ];
                targets = [
                  "x86_64-unknown-linux-gnu"
                  "x86_64-unknown-linux-musl"
                ];
              })
            ];

            shellHook = ''
              # nix develop shells will by default overwrite the $SHELL variable with a
              # non-interactive version of bash. The deviates from how nix-shell works.
              # This fix was taken from:
              #    https://discourse.nixos.org/t/interactive-bash-with-nix-develop-flake/15486
              #
              # See also: nixpkgs#5131 nixpkgs#6091
              export SHELL=${pkgs.bashInteractive}/bin/bash
            '';

            packages = with pkgs; [
              (python314.withPackages (ps: [ ]))
              (google-fonts.override { fonts = [ "Bungee" ]; })
              nix-claude-code.packages.x86_64-linux."2.1.112"
              wget
              lua
              jq
              typst
              gnumake
              ripgrep
              imagemagick
            ];
          };
      }
    );
}
