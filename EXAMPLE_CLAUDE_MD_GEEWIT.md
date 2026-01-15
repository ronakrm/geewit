# Geewit + Claude Code: Parallel Development Instructions

This is a project-agnostic template for CLAUDE.md files. Copy the relevant sections below into your project's CLAUDE.md to enable parallel development with git worktrees and Claude Code agents.

---

## Instructions to Copy

Add the following sections to your project's CLAUDE.md file, replacing `<project>` with your actual project/directory name.

---

### Branch Layout

This repo may have multiple branches checked out in separate local folders:
- `../<project>` - main branch
- `../<project>-<branch-name>` - feature/topic branches (e.g., `../<project>-feature-auth`)

Each folder is independent. The `.venv` folder is not copied between branches. When working in a new branch folder, run `uv sync` (or your package manager's equivalent) to set up the virtual environment.

---

### Geewit (gwt) - Parallel Development with Claude Code Agents

The `gwt` command (geewit) manages git worktrees with integrated tmux sessions and Claude Code agents. This enables parallel development across multiple branches.

#### Creating a New Branch with Agent

```bash
# Create worktree + tmux session + Claude Code agent
gwt new <branch-name> -d

# Example: Create a feature branch with agent
gwt new feature-auth -d
```

This creates:
- Git branch: `<branch-name>`
- Worktree folder: `../<project>-<branch-name>`
- Tmux session: `<project>-<branch-name>`
- Claude Code agent running in left pane (with `--dangerously-skip-permissions`)

#### Managing Worktrees

```bash
# List all worktrees and their tmux sessions
gwt list

# Switch to a worktree's tmux session
gwt switch <branch-name>

# Remove a worktree (will prompt for confirmation)
gwt remove <branch-name>

# Force remove without confirmation
yes | gwt remove <branch-name>
```

#### Sending Prompts to Agents

Use `tmux send-keys` to send prompts to agents in their sessions:

```bash
# Send a prompt to an agent (pane 0.0 is the left pane with Claude Code)
tmux send-keys -t <project>-<branch-name>:0.0 'Your prompt here' Enter

# Example: Send implementation task
tmux send-keys -t <project>-feature-auth:0.0 'Implement user authentication with JWT tokens. When done, commit and push.' Enter
```

#### Monitoring Agent Progress

```bash
# Check all agents' status (look for activity indicators)
for session in $(tmux list-sessions -F '#{session_name}' | grep <project>-); do
  echo "=== $session ==="
  tmux capture-pane -t "$session:0.0" -p -S - | grep -E "(✓|●|✶|Complete|Error)" | tail -3
done

# View full output from a specific agent
tmux capture-pane -t <project>-<branch-name>:0.0 -p -S - | tail -50

# Attach to a session to watch live
tmux attach -t <project>-<branch-name>
# (Ctrl+B, D to detach)
```

#### Typical Parallel Development Workflow

1. **Create implementation plan** documenting tasks that can run in parallel
2. **Create worktrees** for each parallel task:
   ```bash
   gwt new task-1 -d
   gwt new task-2 -d
   gwt new task-3 -d
   ```
3. **Send prompts** to each agent with specific task instructions
4. **Monitor progress** periodically
5. **Agents commit and merge** when complete (or push for PR review)
6. **Clean up worktrees** after merging:
   ```bash
   yes | gwt remove task-1
   yes | gwt remove task-2
   yes | gwt remove task-3
   ```

#### Notes

- Agents run with `--dangerously-skip-permissions` for autonomous operation
- Each worktree is independent; agents don't share state
- Run your package manager's sync command (e.g., `uv sync`, `npm install`) if an agent needs dependencies
- Agents cannot checkout `main` from worktrees (it's already checked out in `../<project>`). For merging, agents should push and merge via git commands that don't require checking out main locally.

---

## Example: Filled-In Template

Here's an example of what the instructions look like for a project called "myapp":

```markdown
### Branch Layout

This repo may have multiple branches checked out in separate local folders:
- `../myapp` - main branch
- `../myapp-<branch-name>` - feature/topic branches (e.g., `../myapp-feature-auth`)

### Creating a New Branch with Agent

\`\`\`bash
gwt new feature-auth -d
\`\`\`

This creates:
- Git branch: `feature-auth`
- Worktree folder: `../myapp-feature-auth`
- Tmux session: `myapp-feature-auth`
- Claude Code agent running in left pane

### Sending Prompts

\`\`\`bash
tmux send-keys -t myapp-feature-auth:0.0 'Implement JWT authentication. Commit when done.' Enter
\`\`\`
```

---

## Prerequisites

Before using these instructions, ensure you have:

1. **gwt (geewit) installed** - Git worktree manager with tmux integration
2. **tmux installed** - Terminal multiplexer
3. **Claude Code CLI installed** - Anthropic's CLI for Claude

---

## Tips for Effective Parallel Development

### Task Selection

Good candidates for parallel development:
- Independent features with no shared file modifications
- Separate diagnostic/utility scripts
- Tests for different modules
- Documentation for different components

Poor candidates (run sequentially instead):
- Tasks that modify the same files
- Tasks with dependencies on each other's output
- Refactoring that touches many files

### Prompt Writing

When sending prompts to agents:

1. **Be specific** - Include file paths, function names, expected behavior
2. **Reference docs** - Point to implementation plans or specifications
3. **Set expectations** - "When done, commit and push" or "When done, create a PR"
4. **Include context** - Mention relevant existing code or patterns to follow

Example of a good prompt:
```bash
tmux send-keys -t myapp-feature-auth:0.0 'Read docs/AUTH_SPEC.md for requirements. Implement JWT authentication in src/auth/. Follow the patterns in src/users/ for service structure. Add tests in tests/test_auth.py. When done, commit with message "Add JWT authentication" and push.' Enter
```

### Monitoring Best Practices

- Check agents every 10-15 minutes initially
- Look for error indicators or stalled progress
- Attach to sessions if agents seem stuck
- Keep a terminal open with the monitoring loop running

### Merging Strategy

Options for completing parallel work:

1. **Direct merge to main** (for trusted changes):
   ```bash
   # Agent does: git push && git checkout main && git merge <branch>
   ```

2. **Pull request review** (recommended for significant changes):
   ```bash
   # Agent does: git push -u origin <branch>
   # Then create PR via gh cli or web UI
   ```

3. **Squash merge** (for clean history):
   ```bash
   # After review: git merge --squash <branch>
   ```
