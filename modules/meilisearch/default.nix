# Only used by the tests; see modules/test.
{ pkgs }:

{
  packages = [ pkgs.meilisearch ];

  lib = ./lib.sh;

  service.stop = "meili_test_stop";
}
