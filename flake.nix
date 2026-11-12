{
  description = "Misskey - An interplanetary microblogging platform 🚀";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nodejs = pkgs.callPackage ./pkgs/nodejs.nix { inherit system; };
          # Node.js >= 25 no longer bundles corepack, so run nixpkgs' corepack
          # on the pinned Node. It fetches the pnpm version named in
          # package.json#packageManager.
          pnpmShim = pkgs.writeShellScriptBin "pnpm" ''
            export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
            exec ${nodejs}/bin/node ${pkgs.corepack}/dist/pnpm.js "$@"
          '';
          mkModules = pnpmShim: import ./modules { inherit pkgs nodejs pnpmShim; };
          # The smoke test builds the CLI around a stub pnpm.
          mkCli =
            pnpmShim:
            import ./cli.nix {
              inherit pkgs;
              modules = mkModules pnpmShim;
            };
          cli = mkCli pnpmShim;
        in
        {
          inherit
            pkgs
            nodejs
            cli
            mkCli
            ;
          shell = import ./shell.nix {
            inherit pkgs cli nodejs;
            modules = mkModules pnpmShim;
          };
        };

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (perSystem system));
    in
    {
      devShells = forAllSystems (s: {
        default = s.shell;
      });

      packages = forAllSystems (s: {
        default = s.cli;
        nix-misskey = s.cli;
        nodejs = s.nodejs;
      });

      apps = forAllSystems (s: {
        default = {
          type = "app";
          program = "${s.cli}/bin/nix-misskey";
        };
      });

      # Building the CLI runs shellcheck on every sub-command.
      checks = forAllSystems (s: {
        nix-misskey = s.cli;
        smoke = import ./tests/smoke.nix {
          inherit (s) pkgs mkCli;
        };
      });

      formatter = forAllSystems (s: s.pkgs.nixfmt-tree);
    };
}
