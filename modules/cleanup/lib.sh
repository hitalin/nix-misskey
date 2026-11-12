# shellcheck shell=bash

do_clean() {
  services_stop
  rm -rf data .config/default.yml .config/test.yml
}

do_clean_all() {
  do_clean
  rm -rf node_modules built
}
