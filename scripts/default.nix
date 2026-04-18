{
  pkgs,
  configs,
  nodejs,
  pnpmShim,
}:

{
  misskeyEnv = import ./misskey-env.nix {
    inherit pkgs configs nodejs pnpmShim;
  };
}
