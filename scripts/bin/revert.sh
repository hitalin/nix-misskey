require_misskey_repo
pg_ensure
log "Reverting last migration..."
pnpm revert
