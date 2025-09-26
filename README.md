# geewit

Git worktree helpers with first-class tmux integration for coding agents.

## Requirements
- Linux or WSL with `git` and `tmux`
- Optional: GitHub CLI (`gh`) for `gwt from-pr`
- Optional: any executable you want to start in the "agent" pane

Optimal usage expects basic tmux familiarity—know how to detach, switch panes, enter copy mode, and toggle pane full screen: `Ctrl+b d`, `Ctrl+b o`, `Ctrl+b [`, and `Ctrl+b z` respectively.

## Install
```bash
git clone <repo-url>
cd geewit
./install.sh --agent "my-agent"
```

By default the installer copies `bin/gwt` to `~/.local/bin/gwt` and writes configuration to `~/.config/gwt/config`. Set alternative locations with `--prefix`, `--worktree-base`, or `--dir-prefix`. Re-run the installer with `--force` to overwrite an existing binary.

> **Heads up:** if you're messing with this you probably will have to reload shells otherwise you and agents will get confused.

After installation make sure `~/.local/bin` is on your `PATH`, then run:
```bash
gwt help
```

The installer automatically appends a completion snippet to your detected shell (`~/.bashrc` or `~/.zshrc`). Override the target shell with `--shell bash|zsh` or skip the change entirely with `--skip-shell-config` and add the snippet yourself later.

### Changing the agent later
Use the built-in helper commands:
```bash
gwt agent set "my-other-agent --flag"
gwt agent show
gwt agent clear
```
Configuration lives in `~/.config/gwt/config`; edit it directly if you prefer.

Per session, override the agent pane with `gwt new feature-login --agent "my-temp-agent"` or skip launching one entirely via `gwt new feature-login --no-agent`.

## Daily workflow
- `gwt new feature-branch [base] [--agent cmd]` – create a worktree, split tmux window, start the configured agent (override per session with `--agent`), and open a git status pane; pass a base branch to seed from something other than `main`, even if that branch already has its own gwt worktree
- `gwt switch feature-branch` – reattach to the tmux session
- `gwt list` – list worktrees plus matching tmux sessions
- `gwt remove feature-branch` – remove the worktree and tmux session after the branch is merged
- `gwt status` – get an overview of every worktree’s cleanliness and remote sync state
- `gwt cleanup` – interactively prune worktrees that are already merged into main
- `gwt from-pr 123` – spin up a worktree directly from a GitHub PR (requires `gh`)
- `gwt merge feature-branch [base] [--keep]` – merge a feature branch into the base branch (default `main`) and automatically remove the worktree and local branch unless you pass `--keep`

### Merging branches with cleanup
`gwt merge feature-branch [base]` orchestrates a fast-forward-preventing merge inside the primary worktree (usually the clone you installed from). Both the target branch and the base must be clean; the command will abort with a helpful message if either contains uncommitted changes.

After a successful merge it:
- Switches back to the base branch so you can continue working in the primary clone.
- Removes the feature worktree, tmux session, and VS Code workspace folder entry.
- Deletes the local git branch. Use `--keep` to skip the cleanup if you want to retain any of those.

Conflicts are surfaced in the primary worktree; resolve them there, commit, and rerun `gwt merge` to finish cleanup.

## Where worktrees live
By default `gwt` creates worktrees next to your repository (one directory up from the repo root) using the pattern `<repo-name>-<branch>`. For example, running `gwt new feature-login` inside `~/src/myapp` will create `~/src/myapp-feature-login`.

Customize the location with either of the following:
- `--worktree-base PATH` when running `./install.sh` (relative paths resolve from the repo root)
- `gwt config-path` shows the config file (`~/.config/gwt/config`); edit or set `GWT_WORKTREE_BASE=/absolute/or/relative/path` and `GWT_PREFIX=prefix-` if you prefer a directory prefix.

## Tmux status bar
Every session created by `gwt new` configures the tmux status bar to call `gwt tmux-status`. The right side shows the branch name, staged/modified/untracked counts, and upstream sync arrows so you can see repo state at a glance from any pane.

## Uninstall
Remove the binary and config:
```bash
rm ~/.local/bin/gwt
rm -r ~/.config/gwt
```

## Optional shell helpers
For shells that still reference the legacy aliases/functions, source the compatibility helpers:
```bash
source /path/to/geewit/share/gwt-profile.sh
```
This removes the old aliases and re-creates thin wrappers that defer to the `gwt` CLI.

## Shell completion
Generate completion scripts from the CLI:
- Bash: `eval "$(gwt completion bash)"`
- Zsh: `eval "$(gwt completion zsh)"`

If you use `share/gwt-profile.sh` it will register the appropriate completion automatically.

## Tips
- Alias frequently used agent arguments (for continuing conversations, granting permissions, etc.) so you can pass them to `gwt` without retyping the full command each time (e.g., `alias ccdsp="claude --dangerously-skip-permissions"`).
- You can invoke `gwt` from any of its worktrees (not just the original clone); the CLI automatically targets the primary repository for shared assets such as tmux sessions and VS Code workspace updates.
