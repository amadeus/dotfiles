function rex-restore --description "Replace local Rex sessions with the saved layout and fresh shells"
    if test (count $argv) -ne 0
        echo 'usage: rex-restore' >&2
        return 1
    end
    command python3 "$__fish_config_dir/scripts/rex-snapshot.py" restore
end
