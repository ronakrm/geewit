# geewit

Git worktree helpers with first-class tmux integration for coding agents.

## Requirements
- Linux or WSL with `git` and `tmux`
- Optional: GitHub CLI (`gh`) for `gwt from-pr`
- Optional: any executable you want to start in the "agent" pane

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

## Daily workflow
- `gwt new feature-branch` – create a worktree, split tmux window, start the configured agent, and open a git status pane
- `gwt switch feature-branch` – reattach to the tmux session
- `gwt list` – list worktrees plus matching tmux sessions
- `gwt remove feature-branch` – remove the worktree and tmux session after the branch is merged
- `gwt status` – get an overview of every worktree’s cleanliness and remote sync state
- `gwt cleanup` – interactively prune worktrees that are already merged into main
- `gwt from-pr 123` – spin up a worktree directly from a GitHub PR (requires `gh`)

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
