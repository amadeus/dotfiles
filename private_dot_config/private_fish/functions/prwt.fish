function prwt --description "Check out a PR into a sibling worktree"
    if test (count $argv) -ne 1
        echo "usage: prwt <pr-number>"
        return 1
    end

    set pr $argv[1]
    if not string match -rq '^[0-9]+$' -- $pr
        echo "prwt: PR number must be numeric"
        return 1
    end

    set root (command git rev-parse --show-toplevel 2>/dev/null)
    if test $status -ne 0
        echo "prwt: not inside a git worktree"
        return 1
    end

    set parent (path dirname "$root")
    set branch "pr_$pr"
    set worktree_path "$parent/$branch"

    if test -e "$worktree_path"
        echo "prwt: worktree path already exists: $worktree_path"
        return 1
    end

    set pr_info (command gh pr view $pr --json headRefName,headRepositoryOwner --jq '.headRefName, .headRepositoryOwner.login')
    or return $status

    if test (count $pr_info) -ne 2
        echo "prwt: failed to read PR head branch information"
        return 1
    end

    set pr_head_ref $pr_info[1]
    set pr_head_owner $pr_info[2]

    set origin_url (command git -C "$root" remote get-url origin 2>/dev/null)
    if test -z "$origin_url"
        echo "prwt: origin remote is missing"
        return 1
    end

    set origin_parts (string match -r --groups-only "^([[:alpha:]][[:alnum:]+.-]*://[^/]+/)([^/]+)/(.*)\$" -- "$origin_url")
    if test (count $origin_parts) -eq 3
        set pr_head_repo_url "$origin_parts[1]$pr_head_owner/$origin_parts[3]"
    else
        set origin_parts (string match -r --groups-only "^([^@]+@[^:]+:)([^/]+)/(.*)\$" -- "$origin_url")
        if test (count $origin_parts) -eq 3
            set pr_head_repo_url "$origin_parts[1]$pr_head_owner/$origin_parts[3]"
        else
            echo "prwt: unsupported origin remote URL: $origin_url"
            return 1
        end
    end

    set remote_name (command git -C "$root" remote | while read -l remote
        set remote_url (command git -C "$root" remote get-url "$remote" 2>/dev/null)
        if test "$remote_url" = "$pr_head_repo_url"
            echo $remote
            break
        end
    end)

    if test -z "$remote_name"
        set remote_name (string lower -- "$pr_head_owner")
        if contains -- "$remote_name" (command git -C "$root" remote)
            set remote_name "$remote_name-pr"
        end

        command git -C "$root" remote add "$remote_name" "$pr_head_repo_url"
        or return $status
    end

    command git -C "$root" fetch "$remote_name" "$pr_head_ref"
    or return $status

    command git -C "$root" checkout -b "$branch" --track "$remote_name/$pr_head_ref"
    or return $status

    command git -C "$root" checkout main
    or return $status

    command git -C "$root" worktree add "$worktree_path" "$branch"
    or return $status
end
