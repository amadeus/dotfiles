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

    command gh pr checkout $pr -b $branch
    or return $status

    command git -C "$root" checkout main
    or return $status

    command git -C "$root" worktree add "$worktree_path" $branch
end
