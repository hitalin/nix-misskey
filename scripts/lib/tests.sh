# shellcheck shell=bash
# Test environment + runners. Always destructively re-init the test DB.

test_setup_env() {
  pg_stop
  redis_stop
  pg_init
  redis_init
  createdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" misskey-test
  mkdir -p .config
  install -m 644 "$MISSKEY_TEST" .config/test.yml
}

test_cleanup_env() {
  if pg_running; then
    dropdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" misskey-test 2>/dev/null || true
  fi
  pg_stop
  redis_stop
  rm -f .config/test.yml
}

run_test_unit() {
  test_setup_env
  local rc=0
  pnpm --filter backend build
  pnpm --filter backend exec cross-env NODE_ENV=test jest \
    --detectOpenHandles --runInBand --testTimeout=30000 --no-cache || rc=$?
  test_cleanup_env
  return $rc
}

run_test_e2e() {
  test_setup_env
  local rc=0
  pnpm --filter backend build
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm build:test
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm test:e2e \
    --detectOpenHandles --runInBand --testTimeout=30000 || rc=$?
  test_cleanup_env
  return $rc
}

run_test_all() {
  test_setup_env
  local rc=0
  pnpm --filter frontend exec cross-env NODE_ENV=test jest || rc=$?
  pnpm --filter misskey-js exec cross-env NODE_ENV=test jest || rc=$?
  pnpm --filter backend build
  pnpm --filter backend exec cross-env NODE_ENV=test jest \
    --detectOpenHandles --runInBand --testTimeout=30000 || rc=$?
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm build:test || rc=$?
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm test:e2e \
    --detectOpenHandles --runInBand --testTimeout=30000 || rc=$?
  test_cleanup_env
  return $rc
}
