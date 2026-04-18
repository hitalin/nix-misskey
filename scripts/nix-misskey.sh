#!/usr/bin/env bash
# nix-misskey - Misskey development environment helper
# This file is rendered by Nix; @VAR@ placeholders are substituted at build time.

set -euo pipefail

PG_CONF='@PG_CONF@'
PG_HBA='@PG_HBA@'
REDIS_CONF='@REDIS_CONF@'
MISSKEY_DEFAULT='@MISSKEY_DEFAULT@'
MISSKEY_TEST='@MISSKEY_TEST@'

export PATH='@PATH_PREFIX@':"$PATH"

export NODE_ENV="${NODE_ENV:-development}"
export VITE_PORT="${VITE_PORT:-5173}"
export EMBED_VITE_PORT="${EMBED_VITE_PORT:-5174}"
export PORT="${PORT:-3000}"
export PGDATA="${PGDATA:-$(pwd)/data/postgres}"
export PGHOST="${PGHOST:-localhost}"
export PGDATABASE="${PGDATABASE:-misskey}"
export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-postgres}"
export PGPORT="${PGPORT:-5433}"
export LC_ALL="${LC_ALL:-C}"
export LANG="${LANG:-C}"

REDIS_DIR="$(pwd)/data/redis"
LOG_DIR="$(pwd)/data/logs"

# ---------- helpers ----------
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[0;33m'
NC=$'\033[0m'

log()     { printf '%s[Misskey]%s %s\n' "$BLUE"   "$NC" "$1"; }
success() { printf '%s✓%s %s\n'         "$GREEN"  "$NC" "$1"; }
warn()    { printf '%s!%s %s\n'         "$YELLOW" "$NC" "$1"; }
error()   { printf '%s✗%s %s\n'         "$RED"    "$NC" "$1" >&2; return 1; }

require_misskey_repo() {
  if [ ! -f package.json ] || ! grep -q '"name": "misskey"' package.json 2>/dev/null; then
    error "Run this command from the root of the misskey repository"
  fi
}

show_help() {
  cat <<EOF
Misskey Development Environment

Usage: nix-misskey <command> [args]

Commands:
  setup       Initialize PostgreSQL, Redis, config and install dependencies
  start       Start dev server (frontend + backend)
  stop        Stop PostgreSQL and Redis
  restart     stop && start
  status      Show service status
  reset       clean && setup
  clean       Remove data, node_modules and config
  psql        Connect to misskey database
  redis-cli   Open redis-cli session
  logs [svc]  Tail logs (postgres|redis|misskey|all)
  test        Run all tests
  test:unit   Run backend unit tests
  test:e2e    Run backend e2e tests
  help        Show this help
EOF
}

# ---------- postgres ----------
pg_running() { pg_isready -h "$PGHOST" -p "$PGPORT" >/dev/null 2>&1; }

pg_start() {
  if pg_running; then return 0; fi
  mkdir -p "$PGDATA/log"
  pg_ctl -D "$PGDATA" -l "$PGDATA/log/postgresql.log" -o "-k $PGDATA" start
  for _ in $(seq 1 30); do
    pg_running && return 0
    sleep 1
  done
  error "PostgreSQL failed to start"
}

pg_stop() {
  if pg_running; then
    pg_ctl -D "$PGDATA" stop -m fast || true
  fi
}

setup_postgres() {
  log "Initializing PostgreSQL..."
  pg_stop
  rm -rf "$PGDATA"
  mkdir -p "$PGDATA"

  local pwfile
  pwfile="$(mktemp)"
  trap 'rm -f "$pwfile"' RETURN
  printf '%s' "$PGPASSWORD" > "$pwfile"

  initdb -D "$PGDATA" \
    --auth=scram-sha-256 \
    --no-locale \
    --encoding=UTF8 \
    --username="$PGUSER" \
    --pwfile="$pwfile" >/dev/null

  install -m 600 "$PG_CONF" "$PGDATA/postgresql.conf"
  install -m 600 "$PG_HBA"  "$PGDATA/pg_hba.conf"

  pg_start
  createdb -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$PGDATABASE"
  success "PostgreSQL initialized"
}

# ---------- redis ----------
redis_running() { redis-cli -p 6379 ping >/dev/null 2>&1; }

redis_start() {
  if redis_running; then return 0; fi
  mkdir -p "$REDIS_DIR"
  install -m 644 "$REDIS_CONF" "$REDIS_DIR/redis.conf"
  redis-server "$REDIS_DIR/redis.conf"
  for _ in $(seq 1 10); do
    redis_running && return 0
    sleep 1
  done
  error "Redis failed to start"
}

redis_stop() {
  if redis_running; then
    redis-cli shutdown nosave 2>/dev/null || true
  fi
}

setup_redis() {
  log "Initializing Redis..."
  redis_stop
  rm -rf "$REDIS_DIR"
  redis_start
  success "Redis initialized"
}

# ---------- misskey config ----------
setup_config() {
  log "Creating Misskey configuration..."
  mkdir -p .config
  install -m 644 "$MISSKEY_DEFAULT" .config/default.yml
  success "Configuration created"
}

# ---------- main commands ----------
cmd_setup() {
  require_misskey_repo
  setup_postgres
  setup_redis
  setup_config
  log "Installing dependencies..."
  git submodule update --init
  pnpm install --frozen-lockfile
  log "Building Misskey..."
  pnpm build
  log "Running migrations..."
  pnpm migrate
  success "Setup completed"
}

cmd_start() {
  require_misskey_repo
  pg_start
  redis_start
  mkdir -p "$LOG_DIR"
  log "Starting Misskey (frontend + backend)..."
  pnpm dev
}

cmd_stop() {
  log "Stopping services..."
  pg_stop
  redis_stop
  success "Services stopped"
}

cmd_status() {
  if pg_running;    then success "PostgreSQL: running on $PGPORT"; else warn "PostgreSQL: not running"; fi
  if redis_running; then success "Redis: running on 6379";          else warn "Redis: not running"; fi
}

cmd_clean() {
  cmd_stop
  rm -rf data node_modules .config/default.yml .config/test.yml
  success "Environment cleaned"
}

cmd_logs() {
  local svc="${1:-all}"
  case "$svc" in
    postgres) tail -F "$PGDATA"/log/*.log ;;
    redis)    tail -F "$REDIS_DIR"/redis.log ;;
    misskey)  tail -F "$LOG_DIR"/* 2>/dev/null || warn "no misskey logs yet" ;;
    all)
      shopt -s nullglob
      local files=("$PGDATA"/log/*.log "$REDIS_DIR"/redis.log "$LOG_DIR"/*)
      shopt -u nullglob
      [ ${#files[@]} -gt 0 ] || error "no logs to tail"
      tail -F "${files[@]}"
      ;;
    *) error "unknown log target: $svc (postgres|redis|misskey|all)" ;;
  esac
}

# ---------- tests ----------
setup_test_env() {
  log "Setting up test environment..."
  cmd_stop
  setup_postgres
  setup_redis
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

# ---------- dispatch ----------
case "${1:-help}" in
  setup)     cmd_setup ;;
  start)     cmd_start ;;
  stop)      cmd_stop ;;
  restart)   cmd_stop && cmd_start ;;
  status)    cmd_status ;;
  reset)     cmd_clean && cmd_setup ;;
  clean)     cmd_clean ;;
  psql)      psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$PGDATABASE" ;;
  redis-cli) redis-cli ;;
  logs)      shift; cmd_logs "${1:-all}" ;;
  test)      cmd_test_all ;;
  test:unit) cmd_test_unit ;;
  test:e2e)  cmd_test_e2e ;;
  help|-h|--help) show_help ;;
  *) show_help; exit 1 ;;
esac
