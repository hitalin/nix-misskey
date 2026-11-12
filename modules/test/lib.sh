# shellcheck shell=bash
# Test environment + runners. Tests get their own database (misskey-test) and
# Redis DB, so the dev database is left untouched and services stay up.

test_setup_env() {
  services_ensure
  meili_test_start
  dropdb --if-exists -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$MISSKEY_TEST_DB"
  createdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$MISSKEY_TEST_DB"
  mkdir -p .config
  install -m 644 "$MISSKEY_TEST" .config/test.yml
}

test_cleanup_env() {
  meili_test_stop
  dropdb --if-exists -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$MISSKEY_TEST_DB" || true
  rm -f .config/test.yml
}

# Runners delegate to upstream package.json scripts (which build what they
# need). Extra arguments are forwarded to vitest.

run_test_unit() {
  test_setup_env
  local rc=0
  pnpm --filter backend test --run "$@" || rc=$?
  test_cleanup_env
  return $rc
}

run_test_e2e() {
  test_setup_env
  local rc=0
  pnpm --filter backend test:e2e --run "$@" || rc=$?
  test_cleanup_env
  return $rc
}

run_test_all() {
  test_setup_env
  local rc=0
  pnpm --filter frontend test || rc=$?
  pnpm --filter misskey-js test || rc=$?
  pnpm --filter backend test --run || rc=$?
  pnpm --filter backend test:e2e --run || rc=$?
  test_cleanup_env
  return $rc
}
