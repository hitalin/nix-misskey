exec psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" "$PGDATABASE" "$@"
