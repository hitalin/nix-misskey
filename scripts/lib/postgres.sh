# shellcheck shell=bash
# PostgreSQL primitives. Higher-level commands compose these.

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

# Destructive: wipe PGDATA and re-initialize.
pg_init() {
  log "Initializing PostgreSQL..."
  pg_stop
  rm -rf "$PGDATA"
  mkdir -p "$PGDATA"

  local pwfile
  pwfile="$(mktemp)"
  # local vars are out of scope when RETURN fires; expand $pwfile at trap-set time.
  # shellcheck disable=SC2064
  trap "rm -f '$pwfile'" RETURN
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

# Idempotent: init only when missing, otherwise just start.
pg_ensure() {
  if [ ! -f "$PGDATA/PG_VERSION" ]; then
    pg_init
  else
    pg_start
  fi
}
