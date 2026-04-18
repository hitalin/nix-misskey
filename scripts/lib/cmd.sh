# shellcheck shell=bash
# Higher-level command bodies composed from primitives.
# bin/*.sh stays as a thin wrapper that calls these.

do_clean() {
  pg_stop
  redis_stop
  rm -rf data node_modules .config/default.yml .config/test.yml
}

do_setup() {
  pg_ensure
  redis_ensure
  ensure_config
  log "Installing dependencies..."
  git submodule update --init
  pnpm install --frozen-lockfile
  log "Building Misskey (production)..."
  if ! pnpm build; then
    warn "Full build failed (often a frontend i18n issue in forks)."
    warn "Continuing — frontend will be compiled on demand by 'nix-misskey app dev'."
  fi
  log "Running migrations..."
  pnpm migrate
}

do_dev() {
  pg_ensure
  redis_ensure
  ensure_config
  if [ ! -d node_modules ]; then
    error "Dependencies not installed. Run 'nix-misskey app setup' first."
  fi
  mkdir -p "$LOG_DIR"
  pnpm dev
}
