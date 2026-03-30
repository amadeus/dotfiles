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

    set pr_info (command gh pr view $pr --json headRefName,headRepository,headRepositoryOwner --jq '[.headRefName, .headRepositoryOwner.login, .headRepository.url] | @tsv')
    or return $status

    set pr_head_ref $pr_info[1]
    set pr_head_owner $pr_info[2]
    set pr_head_repo_url $pr_info[3]

    set remote_name (command git -C "$root" remote | while read -l remote
        set remote_url (command git -C "$root" remote get-url "$remote" 2>/dev/null)
        if test "$remote_url" = "$pr_head_repo_url"
            echo $remote
            break
        end
    end)

    if test -z "$remote_name"
        set remote_name (string lower -- "$pr_head_owner")
        if command git -C "$root" remote get-url "$remote_name" >/dev/null 2>/dev/null
            set remote_name "$remote_name-pr"
        end

        command git -C "$root" remote add "$remote_name" "$pr_head_repo_url"
        or return $status
    end

    command git -C "$root" fetch "$remote_name" "$pr_head_ref"
    or return $status

    command gh pr checkout $pr -b $branch
    or return $status

    command git -C "$root" branch --set-upstream-to="$remote_name/$pr_head_ref" "$branch"
    or return $status

    command git -C "$root" checkout main
    or return $status

    command git -C "$root" worktree add "$worktree_path" $branch
    or return $status
end
