# shellcheck shell=bash
# Misskey itself: config, dependencies, migrations, dev server.

LOG_DIR="$PWD/data/logs"

ensure_config() {
  if [ ! -f .config/default.yml ]; then
    log "Creating Misskey configuration..."
    mkdir -p .config
    install -m 644 "$MISSKEY_DEFAULT" .config/default.yml
    success "Configuration created"
  fi
}

do_setup() {
  services_ensure
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

# Applied migrations in the nix-misskey database; 0 when it has none yet.
migration_count() {
  psql -XAtq -v ON_ERROR_STOP=1 <<'SQL'
SELECT to_regclass('public.migrations') IS NOT NULL AS has_table \gset
\if :has_table
SELECT count(*) FROM migrations;
\else
SELECT 0;
\endif
SQL
}

do_dev() {
  services_ensure
  ensure_config
  # Set up by itself only with the stock config: an edited one may point at a
  # database that is not ours to migrate.
  if cmp -s "$MISSKEY_DEFAULT" .config/default.yml; then
    local migrated
    migrated="$(migration_count)" \
      || error "Cannot query database '$PGDATABASE' on port $PGPORT"
    if [ ! -d node_modules ] || [ "$migrated" = 0 ]; then
      log "Not set up yet; running setup first..."
      do_setup
    fi
  elif [ ! -d node_modules ]; then
    error "Dependencies not installed. Run 'nix-misskey setup' first."
  fi
  mkdir -p "$LOG_DIR"
  log "Starting Misskey (frontend + backend)..."
  NODE_ENV=development pnpm dev
}
