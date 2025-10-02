#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
PREFIX="${PREFIX:-$HOME/.local}"
AGENT_COMMAND=""
WORKTREE_BASE=""
DIR_PREFIX=""
FORCE=0
SHELL_TARGET="${GWT_INSTALL_SHELL:-}"
SKIP_SHELL_CONFIG=0
COMPLETION_NOTE=""

usage() {
    cat <<'EOS'
Usage: ./install.sh [options]

Options
  --prefix DIR          Install path prefix (default: ~/.local)
  --agent CMD           Command to start in the agent pane (quoted if it has spaces)
  --worktree-base PATH  Default location for new worktrees (relative paths are resolved from the repo root)
  --dir-prefix STR      Prefix to add to generated worktree directory names
  --force               Overwrite existing gwt binary without prompting
  --shell SHELL         Force shell config update for bash or zsh (default: detect from \$SHELL)
  --skip-shell-config   Skip modifying shell rc files
  --help                Show this help

The installer copies bin/gwt to <prefix>/bin/gwt and updates ~/.config/gwt/config.
EOS
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            [[ $# -ge 2 ]] || { echo "--prefix requires a value" >&2; exit 1; }
            PREFIX="$2"
            shift 2
            ;;
        --agent)
            [[ $# -ge 2 ]] || { echo "--agent requires a value" >&2; exit 1; }
            AGENT_COMMAND="$2"
            shift 2
            ;;
        --worktree-base)
            [[ $# -ge 2 ]] || { echo "--worktree-base requires a value" >&2; exit 1; }
            WORKTREE_BASE="$2"
            shift 2
            ;;
        --dir-prefix)
            [[ $# -ge 2 ]] || { echo "--dir-prefix requires a value" >&2; exit 1; }
            DIR_PREFIX="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --shell)
            [[ $# -ge 2 ]] || { echo "--shell requires a value" >&2; exit 1; }
            case "$2" in
                bash|zsh)
                    SHELL_TARGET="$2"
                    ;;
                *)
                    echo "Unsupported shell for --shell: $2" >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --skip-shell-config)
            SKIP_SHELL_CONFIG=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

BIN_TARGET="$PREFIX/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gwt"
CONFIG_FILE="$CONFIG_DIR/config"
SOURCE_BIN="$PROJECT_ROOT/bin/gwt"
TARGET_BIN="$BIN_TARGET/gwt"

if [[ ! -f "$SOURCE_BIN" ]]; then
    echo "install.sh: unable to find $SOURCE_BIN" >&2
    exit 1
fi

mkdir -p "$BIN_TARGET"

if [[ -f "$TARGET_BIN" && $FORCE -ne 1 ]]; then
    read -r -p "$TARGET_BIN exists. Overwrite? [y/N] " reply
    if [[ ! "$reply" =~ ^[Yy]$ ]]; then
        echo "aborted"
        exit 1
    fi
fi

install -m 755 "$SOURCE_BIN" "$TARGET_BIN"

installed_version=""
if installed_version="$("$TARGET_BIN" --version 2>/dev/null)"; then
    if [[ -n "$installed_version" ]]; then
        echo "✓ installed $installed_version to $TARGET_BIN"
    else
        echo "✓ installed to $TARGET_BIN"
    fi
else
    echo "✓ installed to $TARGET_BIN"
fi

mkdir -p "$CONFIG_DIR"
touch "$CONFIG_FILE"

write_config() {
    local key="$1"
    local value="$2"
    local escaped
    escaped=$(printf '%q' "$value")
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        sed -i "s|^${key}=.*$|${key}=${escaped}|" "$CONFIG_FILE"
    else
        printf '%s=%s\n' "$key" "$escaped" >> "$CONFIG_FILE"
    fi
}

configure_shell_completion() {
    if [[ $SKIP_SHELL_CONFIG -eq 1 ]]; then
        COMPLETION_NOTE="Shell completion skipped (--skip-shell-config)."
        return
    fi

    local shell_choice="${SHELL_TARGET}"
    if [[ -z "$shell_choice" ]]; then
        shell_choice=$(basename "${SHELL:-}")
    fi

    local rc_file=""
    case "$shell_choice" in
        bash)
            rc_file="$HOME/.bashrc"
            ;;
        zsh)
            rc_file="$HOME/.zshrc"
            ;;
        "" )
            COMPLETION_NOTE="Shell completion: add 'eval \"\$(gwt completion bash)\"' to your shell rc manually."
            return
            ;;
        *)
            COMPLETION_NOTE="Shell completion: unsupported shell '$shell_choice'. Add 'eval \"\$(gwt completion bash)\"' to your shell rc manually."
            return
            ;;
    esac

    local marker="# geewit gwt completion (auto)"
    mkdir -p "$(dirname "$rc_file")"
    touch "$rc_file"

    if grep -Fq "$marker" "$rc_file"; then
        COMPLETION_NOTE="Shell completion already configured in $rc_file"
        return
    fi

    # Ensure we start on a new line when appending.
    if [[ -s "$rc_file" ]]; then
        printf '\n' >> "$rc_file"
    fi

    local completion_line="    eval \"\$(gwt completion $shell_choice)\""

    {
        printf '%s\n' "$marker"
        printf '%s\n' 'if command -v gwt >/dev/null 2>&1; then'
        printf '%s\n' "$completion_line"
        printf '%s\n\n' 'fi'
    } >> "$rc_file"

    COMPLETION_NOTE="✓ added completion hook to $rc_file"
}

if [[ -n "$AGENT_COMMAND" ]]; then
    write_config GWT_AGENT_COMMAND "$AGENT_COMMAND"
    echo "✓ set agent command"
fi

if [[ -n "$WORKTREE_BASE" ]]; then
    write_config GWT_WORKTREE_BASE "$WORKTREE_BASE"
    echo "✓ set worktree base"
fi

if [[ -n "$DIR_PREFIX" ]]; then
    write_config GWT_PREFIX "$DIR_PREFIX"
    echo "✓ set worktree directory prefix"
fi

echo "Config file: $CONFIG_FILE"

echo "Add $BIN_TARGET to your PATH if you have not already."

if [[ -f "$PROJECT_ROOT/share/gwt-profile.sh" ]]; then
    echo "Optional: source $PROJECT_ROOT/share/gwt-profile.sh in your shell rc to reset legacy aliases."
fi

configure_shell_completion

if [[ -n "$COMPLETION_NOTE" ]]; then
    echo "$COMPLETION_NOTE"
fi

echo "Done. Run 'gwt help' for available commands."
