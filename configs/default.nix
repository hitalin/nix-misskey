{ pkgs }:

{
  misskey = import ./misskey { inherit pkgs; };
  redis = import ./redis.nix { inherit pkgs; };
  postgres = import ./postgres.nix { inherit pkgs; };
}
