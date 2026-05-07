# Fish completions for cct (claude code tmux launcher)

function __cct_args
    # Positional args after `cct`, with flags stripped.
    set -l tokens (commandline -opc)
    set -e tokens[1]
    for t in $tokens
        switch $t
            case '-k' '--backup-key'
                continue
            case '*'
                echo $t
        end
    end
end

function __cct_needs_command
    set -l args (__cct_args)
    test (count $args) -eq 0
end

function __cct_using_at
    # __cct_using_at <subcommand> <position>
    # Position is 1-based, counting args after `cct` (so the subcommand itself is position 1).
    set -l sub $argv[1]
    set -l pos $argv[2]
    set -l args (__cct_args)
    test (count $args) -ge 1
    and test "$args[1]" = "$sub"
    and test (count $args) -eq $pos
end

function __cct_worktree_names
    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    or return
    set -l repo_name (basename $repo_root)
    set -l parent (dirname $repo_root)
    for d in $parent/$repo_name-*
        if test -d $d
            string replace -- "$repo_name-" "" (basename $d)
        end
    end
end

function __cct_branches
    git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null
    git for-each-ref --format='%(refname:short)' refs/remotes/ 2>/dev/null \
        | string replace -r '^[^/]+/' '' \
        | string match -v HEAD
end

# No file completion.
complete -c cct -f

# Subcommands (only when no subcommand has been entered yet).
complete -c cct -n __cct_needs_command -a new    -d 'New worktree on new branch'
complete -c cct -n __cct_needs_command -a check  -d 'Worktree on existing branch'
complete -c cct -n __cct_needs_command -a resume -d 'Resume existing worktree'
complete -c cct -n __cct_needs_command -a rm     -d 'Remove worktree'
complete -c cct -n __cct_needs_command -a ls     -d 'List worktrees and sessions'

# Backup-key flag (allowed at any position).
complete -c cct -s k -l backup-key -d 'Use $BACKUP_ANTHROPIC_KEY for claude'

# Force-remove flag (only valid for `cct rm`).
complete -c cct -n '__fish_seen_subcommand_from rm' -s f -l force \
    -d 'Force remove worktree (allow uncommitted changes)'

# Per-subcommand positional completions.
complete -c cct -n '__cct_using_at check 1'  -a '(__cct_branches)'       -d branch
complete -c cct -n '__cct_using_at resume 1' -a '(__cct_worktree_names)' -d worktree
complete -c cct -n '__cct_using_at rm 1'     -a '(__cct_worktree_names)' -d worktree
# `cct new <name> [base]` — name is freeform; offer branches for the optional base.
complete -c cct -n '__cct_using_at new 2'    -a '(__cct_branches)'       -d 'base branch'
