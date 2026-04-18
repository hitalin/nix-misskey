# shellcheck shell=bash
# Misskey runtime config (.config/default.yml) lifecycle.

# Idempotent: install default.yml only if missing.
ensure_config() {
  if [ ! -f .config/default.yml ]; then
    log "Creating Misskey configuration..."
    mkdir -p .config
    install -m 644 "$MISSKEY_DEFAULT" .config/default.yml
    success "Configuration created"
  fi
}
