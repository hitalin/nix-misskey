# shellcheck shell=bash
# Misskey config (.config/default.yml) lifecycle.

ensure_config() {
  if [ ! -f .config/default.yml ]; then
    log "Creating Misskey configuration..."
    mkdir -p .config
    install -m 644 "$MISSKEY_DEFAULT" .config/default.yml
    success "Configuration created"
  fi
}
