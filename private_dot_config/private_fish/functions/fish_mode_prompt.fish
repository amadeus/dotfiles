function fish_mode_prompt --description 'Display vi prompt mode'
    # Based on the original fish_default_mode_prompt from your system
    if test "$fish_key_bindings" = fish_vi_key_bindings
        or test "$fish_key_bindings" = fish_hybrid_key_bindings
        switch $fish_bind_mode
            case default
                set_color --bold red
                echo -n n
            case insert
                set_color --bold green
                echo -n i
            case replace_one
                set_color --bold green
                echo -n r
            case replace
                set_color --bold cyan
                echo -n r
            case visual
                set_color --bold magenta
                echo -n v
        end
        set_color normal
        echo -n ' '
    end
end
