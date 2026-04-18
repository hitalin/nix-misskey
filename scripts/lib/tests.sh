# shellcheck shell=bash
# Test environment + test runners. Always destructively re-init the test DB.

setup_test_env() {
  log "Setting up test environment..."
  cmd_stop
  init_postgres
  init_redis
  createdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" misskey-test
  mkdir -p .config
  install -m 644 "$MISSKEY_TEST" .config/test.yml
  success "Test environment ready"
}

cleanup_test_env() {
  log "Cleaning up test environment..."
  if pg_running; then
    dropdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" misskey-test 2>/dev/null || true
  fi
  cmd_stop
  rm -f .config/test.yml
  success "Test environment cleaned up"
}

cmd_test_unit() {
  require_misskey_repo
  setup_test_env
  log "Running backend unit tests..."
  local rc=0
  pnpm --filter backend build
  pnpm --filter backend exec cross-env NODE_ENV=test jest \
    --detectOpenHandles --runInBand --testTimeout=30000 --no-cache || rc=$?
  cleanup_test_env
  return $rc
}

cmd_test_e2e() {
  require_misskey_repo
  setup_test_env
  log "Running backend e2e tests..."
  local rc=0
  pnpm --filter backend build
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm build:test
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm test:e2e \
    --detectOpenHandles --runInBand --testTimeout=30000 || rc=$?
  cleanup_test_env
  return $rc
}

cmd_test_all() {
  require_misskey_repo
  setup_test_env
  log "Running all tests..."
  local rc=0
  pnpm --filter frontend exec cross-env NODE_ENV=test jest || rc=$?
  pnpm --filter misskey-js exec cross-env NODE_ENV=test jest || rc=$?
  pnpm --filter backend build
  pnpm --filter backend exec cross-env NODE_ENV=test jest \
    --detectOpenHandles --runInBand --testTimeout=30000 || rc=$?
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm build:test || rc=$?
  pnpm --filter backend exec cross-env NODE_ENV=test pnpm test:e2e \
    --detectOpenHandles --runInBand --testTimeout=30000 || rc=$?
  cleanup_test_env
  return $rc
}
