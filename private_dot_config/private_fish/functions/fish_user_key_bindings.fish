function fish_user_key_bindings
    # Cmd+K only clears when the entire command line is empty.
    for mode in default insert visual
        bind -M $mode super-k 'if test -z "$(commandline --current-buffer)"; clear && clear; commandline -f repaint; end'
    end
end
