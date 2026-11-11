# shellcheck shell=bash
# Test environment + runners. Tests get their own database (misskey-test) and
# Redis DB, so the dev database is left untouched and services stay up.

# Meilisearch runs only while tests do, on the port upstream's SearchService
# test hard-codes (packages/backend/test/compose.yml).
MEILI_TEST_PORT=57712
MEILI_TEST_DIR="$PWD/data/meilisearch-test"

meili_test_running() { (exec 3<>"/dev/tcp/127.0.0.1/$MEILI_TEST_PORT") 2>/dev/null; }

meili_test_start() {
  if meili_test_running; then return 0; fi
  mkdir -p "$MEILI_TEST_DIR"
  MEILI_NO_ANALYTICS=true MEILI_ENV=development meilisearch \
    --http-addr "127.0.0.1:$MEILI_TEST_PORT" \
    --db-path "$MEILI_TEST_DIR/data.ms" \
    --dump-dir "$MEILI_TEST_DIR/dumps" \
    >"$MEILI_TEST_DIR/meilisearch.log" 2>&1 &
  echo $! > "$MEILI_TEST_DIR/meilisearch.pid"
  for _ in $(seq 1 100); do
    meili_test_running && return 0
    sleep 0.1
  done
  error "Meilisearch failed to start (see $MEILI_TEST_DIR/meilisearch.log)"
}

meili_test_stop() {
  if [ -f "$MEILI_TEST_DIR/meilisearch.pid" ]; then
    kill "$(cat "$MEILI_TEST_DIR/meilisearch.pid")" 2>/dev/null || true
  fi
  rm -rf "$MEILI_TEST_DIR"
}

test_setup_env() {
  pg_ensure
  redis_ensure
  meili_test_start
  dropdb --if-exists -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" misskey-test
  createdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" misskey-test
  mkdir -p .config
  install -m 644 "$MISSKEY_TEST" .config/test.yml
}

test_cleanup_env() {
  meili_test_stop
  dropdb --if-exists -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" misskey-test || true
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
