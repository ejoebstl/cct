# cct

Claude Code tmux launcher. One git worktree + one tmux session per agent, so multiple Claude Code sessions on the same repo don't step on each other.

## What it does

Launch cct from a git repository. Sessions and worktrees are repository-specific, not global.

- `cct new <name> [base]` — new worktree on `feat/<name>` branched off `base` (default `development`), starts `claude` in a fresh tmux session.
- `cct check <branch>` — worktree on an existing local/remote branch.
- `cct resume <name>` — re-attach to an existing worktree, `claude --resume`.
- `cct rm <name>` — remove the worktree and kill its tmux session (branch is kept).
- `cct ls` — list worktrees and tmux sessions for the current repo.

Tmux sessions are named `<repo>-<name>`. New worktrees auto-symlink `.envrc` and `python_env/` from the main repo (and run `direnv allow`) so shared venvs and env vars work without copying.

## Install

```bash
git clone https://github.com/ejoebstl/cct.git
cd cct
chmod +x cct
ln -s "$PWD/cct" ~/.local/bin/cct
```

Make sure `~/.local/bin` is on your `PATH`. Requires `git`, `tmux`, and `claude`.

### Shell completions

Fish:

```bash
ln -s "$PWD/completions/cct.fish" ~/.config/fish/completions/cct.fish
```

## Switching to a backup API key

Pass `-k` / `--backup-key` to inject `$BACKUP_ANTHROPIC_KEY` into the session as `ANTHROPIC_API_KEY`. Useful when your primary auth is rate-limited or expired.

```bash
export BACKUP_ANTHROPIC_KEY=sk-ant-...
cct resume mywork -k
```

The flag works on `new`, `check`, and `resume`. For a new session, the key is passed via `tmux -e` and picked up immediately. For an **already running** session, `tmux set-environment` updates the session env, but a running `claude` process won't see it until restarted.

To cleanly switch an existing worktree onto the backup key:

1. Exit `claude` in every pane of the session (`/exit` or Ctrl-D).
2. Kill the tmux session so no stale env lingers — either `tmux kill-session -t <repo>-<name>` or just `cct rm` + recreate. Use `cct ls` to confirm no sessions remain for the worktree.
3. Re-launch with the flag: `cct resume <name> -k`.

## Cleaning up manually

If, for some reason, `cct rm` does not work, you can simply terminate the tmux session and remove the git worktree using `git worktree remove`. Branches are not removed by cct.