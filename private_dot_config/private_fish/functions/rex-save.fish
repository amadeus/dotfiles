function rex-save --description "Save local Rex sessions, tabs, pane layouts, names, and directories"
    if test (count $argv) -ne 0
        echo 'usage: rex-save' >&2
        return 1
    end
    command python3 "$__fish_config_dir/scripts/rex-snapshot.py" save
end
