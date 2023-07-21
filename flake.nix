{
  description = "Playing with traefik";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-23.05";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs =
    { self
    , nixpkgs
    , pre-commit-hooks
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };

    in
    {
      checks.${system} = {
        test = pkgs.callPackage ./test.nix { };
        pre-commit = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
          };
        };
      };
      devShells.${system}.default = pkgs.mkShell {
        name = "playing-with-traefik-shell";
        buildInputs = (with pre-commit-hooks.packages.${system};
          [
            nixpkgs-fmt
          ]);

        shellHook = self.checks.${system}.pre-commit.shellHook;

      };
    };
}
