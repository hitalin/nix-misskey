{
  lib = ./lib.sh;

  help = "Cleanup";
  commands = [
    {
      name = "clean";
      description = "Remove data and config (PG / Redis / .config)";
      text = ''
        do_clean
        success "Environment cleaned"
      '';
    }
    {
      name = "clean-all";
      description = "clean + node_modules + built";
      text = ''
        do_clean_all
        success "Environment fully cleaned"
      '';
    }
    {
      name = "reset";
      description = "clean-all + setup";
      text = ''
        require_misskey_repo
        log "Resetting environment..."
        do_clean_all
        do_setup
        success "Reset completed"
      '';
    }
  ];
}
