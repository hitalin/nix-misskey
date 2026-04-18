# shellcheck shell=bash
require_misskey_repo() {
  if [ ! -f package.json ] || ! grep -q '"name": "misskey"' package.json 2>/dev/null; then
    error "Run this command from the root of the misskey repository"
  fi
}
