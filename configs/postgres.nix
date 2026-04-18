{ pkgs }:

{
  conf = pkgs.writeText "postgresql.conf" ''
    listen_addresses = 'localhost'
    port = 5433
    max_connections = 100
    shared_buffers = 128MB
    dynamic_shared_memory_type = posix
    max_wal_size = 1GB
    min_wal_size = 80MB
    log_destination = 'stderr'
    logging_collector = on
    log_directory = 'log'
    log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
    log_rotation_age = 1d
    log_rotation_size = 10MB
    log_line_prefix = '%m [%p] '
    log_timezone = 'UTC'
    datestyle = 'iso, mdy'
    timezone = 'UTC'
    lc_messages = 'C'
    lc_monetary = 'C'
    lc_numeric = 'C'
    lc_time = 'C'
    default_text_search_config = 'pg_catalog.english'
    password_encryption = scram-sha-256
  '';

  hba = pkgs.writeText "pg_hba.conf" ''
    local   all             all                                     scram-sha-256
    host    all             all             127.0.0.1/32            scram-sha-256
    host    all             all             ::1/128                 scram-sha-256
  '';
}
