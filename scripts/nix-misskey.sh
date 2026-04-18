#!/usr/bin/env bash
# nix-misskey - Misskey development environment helper.
# Rendered by Nix; @VAR@ placeholders are substituted at build time.

set -euo pipefail

PG_CONF='@PG_CONF@'
PG_HBA='@PG_HBA@'
REDIS_CONF='@REDIS_CONF@'
MISSKEY_DEFAULT='@MISSKEY_DEFAULT@'
MISSKEY_TEST='@MISSKEY_TEST@'
LIB_DIR='@LIB_DIR@'

export PATH='@PATH_PREFIX@':"$PATH"

export NODE_ENV="${NODE_ENV:-development}"
export VITE_PORT="${VITE_PORT:-5173}"
export EMBED_VITE_PORT="${EMBED_VITE_PORT:-5174}"
export PORT="${PORT:-3000}"
export PGDATA="${PGDATA:-$PWD/data/postgres}"
export PGHOST="${PGHOST:-localhost}"
export PGDATABASE="${PGDATABASE:-misskey}"
export PGUSER="${PGUSER:-postgres}"
export PGPASSWORD="${PGPASSWORD:-postgres}"
export PGPORT="${PGPORT:-5433}"
export LC_ALL="${LC_ALL:-C}"
export LANG="${LANG:-C}"

REDIS_DIR="$PWD/data/redis"
LOG_DIR="$PWD/data/logs"

# shellcheck source=lib/common.sh
. "$LIB_DIR/common.sh"
# shellcheck source=lib/postgres.sh
. "$LIB_DIR/postgres.sh"
# shellcheck source=lib/redis.sh
. "$LIB_DIR/redis.sh"
# shellcheck source=lib/config.sh
. "$LIB_DIR/config.sh"
# shellcheck source=lib/tests.sh
. "$LIB_DIR/tests.sh"

# ---------- top-level commands ----------
cmd_setup() {
  require_misskey_repo
  ensure_postgres
  ensure_redis
  ensure_config
  log "Installing dependencies..."
  git submodule update --init
  pnpm install --frozen-lockfile
  log "Building Misskey (production)..."
  if ! pnpm build; then
    warn "Full build failed (often a frontend i18n issue in forks)."
    warn "Continuing — frontend will be compiled on demand by 'pnpm dev'."
  fi
  log "Running migrations..."
  pnpm migrate
  success "Setup completed"
}

cmd_start() {
  require_misskey_repo
  ensure_postgres
  ensure_redis
  ensure_config
  if [ ! -d node_modules ]; then
    error "Dependencies not installed. Run 'nix-misskey setup' first."
  fi
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
