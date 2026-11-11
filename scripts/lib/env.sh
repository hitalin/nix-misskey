# shellcheck shell=bash
# Environment defaults shared by every sub-command.

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
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
# Cache V8 bytecode across runs: pnpm / rolldown / vite / vitest start faster.
export NODE_COMPILE_CACHE="${NODE_COMPILE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/nix-misskey/node-compile-cache}"

REDIS_DIR="$PWD/data/redis"
LOG_DIR="$PWD/data/logs"
