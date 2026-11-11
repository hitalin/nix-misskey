# shellcheck shell=bash
# Higher-level command bodies composed from primitives.
# bin/*.sh stays as a thin wrapper that calls these.

do_clean() {
  pg_stop
  redis_stop
  rm -rf data .config/default.yml .config/test.yml
}

do_clean_all() {
  do_clean
  rm -rf node_modules built
}

do_setup() {
  pg_ensure
  redis_ensure
  ensure_config
  log "Installing dependencies..."
  git submodule update --init
  pnpm install --frozen-lockfile
  # Only the backend is needed for migrations; 'nix-misskey dev' rebuilds
  # everything else itself, so a full production build here is wasted time.
  log "Building backend..."
  pnpm build-pre
  pnpm --filter backend... build
  log "Running migrations..."
  pnpm migrate
}

do_dev() {
  pg_ensure
  redis_ensure
  ensure_config
  if [ ! -d node_modules ]; then
    error "Dependencies not installed. Run 'nix-misskey setup' first."
  fi
  mkdir -p "$LOG_DIR"
  pnpm dev
}
