require_misskey_repo
pg_ensure
log "Running migrations..."
pnpm migrate
