function rex-session --description "Set up the current Rex session with Neovim and server tabs"
    set -l session_name (string join ' ' -- $argv)
    if test (count $argv) -eq 0; or string match -qr '^\s*$' -- "$session_name"
        echo 'usage: rex-session <session-name>' >&2
        return 1
    end

    if not set -q REX_SESSION; or test -z "$REX_SESSION"
        echo 'rex-session: run this inside a Rex session' >&2
        return 1
    end

    for executable in rex nvim
        if not command -q $executable
            echo "rex-session: $executable is not available in PATH" >&2
            return 1
        end
    end

    # Rex calls tabs windows. Use the session ID so renaming cannot change the target.
    set -l session_id "$REX_SESSION"
    set -l windows (command rex --autostart=false window ls --session "$session_id" --quiet --short=false)
    or return $status

    if test (count $windows) -ne 1
        echo "rex-session: expected exactly 1 tab; found "(count $windows) >&2
        return 1
    end

    command rex --autostart=false session rename -- "$session_id" "$session_name"
    or return $status

    command rex --autostart=false window rename --session "$session_id" -- "$windows[1]" 'Neovim Type Shit'
    or return $status

    command rex --autostart=false window new --session "$session_id" --cwd "$PWD" --focus=false 'Server Type Shit' >/dev/null
    or return $status

    command nvim
end
