# Each module is one feature. All attributes are optional:
#   packages  tools the feature needs (dev shell + CLI PATH)
#   shellPackages  tools only the dev shell needs
#   env       exported variables; values are expanded by the shell
#   vars      CLI-only shell variables
#   lib       shell library sourced by every sub-command
#   service   hooks: name / port / running (status), ensure, stop
#   help      heading for the module's commands in `nix-misskey help`
#   commands  [ { name; description; text; usage ? name; } ]
{
  pkgs,
  nodejs,
  pnpmShim,
}:

let
  lib = pkgs.lib;

  core = import ./core;
  postgres = import ./postgres { inherit pkgs; };
  redis = import ./redis { inherit pkgs; };
  meilisearch = import ./meilisearch { inherit pkgs; };
  misskey = import ./misskey {
    inherit
      pkgs
      nodejs
      pnpmShim
      postgres
      redis
      ;
  };
  services = import ./services {
    inherit pkgs;
    modules = [
      postgres
      redis
      meilisearch
    ];
  };
  cleanup = import ./cleanup;
  test = import ./test { inherit pkgs postgres redis; };

  # Order here is the order of `nix-misskey help`.
  all = [
    core
    misskey
    services
    cleanup
    postgres
    redis
    meilisearch
    test
  ];
in
{
  inherit all;
  packages = lib.concatMap (m: m.packages or [ ]) all;
  shellPackages = lib.concatMap (m: m.shellPackages or [ ]) all;
  env = lib.foldl' (acc: m: acc // (m.env or { })) { } all;
}
