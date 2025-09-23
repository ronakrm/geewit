# shellcheck shell=bash
#
# Optional profile helpers for geewit.
# Source this file from your shell rc (e.g. ~/.bashrc) if you need to
# reset legacy aliases from the old gwt scripts and wire them to the new CLI.

# Remove legacy aliases/functions that may shadow the new CLI.
for name in gwt gws gwl gwr gwc gwp gwst gwpr gwm gwd gwt-new gwt-switch gwt-list gwt-remove gwt-cleanup-merged gwt-push gwt-status gwt-from-pr; do
    unalias "$name" 2>/dev/null || true
    unset -f "$name" 2>/dev/null || true
done

_gwt_cli="${GWT_CLI:-$(command -v gwt 2>/dev/null)}"
if [[ -z "$_gwt_cli" ]]; then
    echo "gwt-profile: cannot find the gwt binary on PATH" >&2
    return 1 2>/dev/null || exit 1
fi

# Helper to invoke the CLI, bypassing shell functions/aliases.
_gwt_cmd() {
    command "$_gwt_cli" "$@"
}

# Re-create convenience aliases as thin wrappers over the CLI.
gwt()       { _gwt_cmd "$@"; }
gws()       { _gwt_cmd switch "$@"; }
gwl()       { _gwt_cmd list "$@"; }
gwr()       { _gwt_cmd remove "$@"; }
gwc()       { _gwt_cmd cleanup "$@"; }
gwp()       { _gwt_cmd push "$@"; }
gwst()      { _gwt_cmd status "$@"; }
gwpr()      { _gwt_cmd from-pr "$@"; }
gwm()       { _gwt_cmd switch main || _gwt_cmd switch master; }
gwd()       { _gwt_cmd switch develop || _gwt_cmd new develop main; }

# Backwards-compatible helper for shells that still call the old functions.
gwt-new() { _gwt_cmd new "$@"; }

gwt-switch() { _gwt_cmd switch "$@"; }

gwt-list() { _gwt_cmd list "$@"; }

gwt-remove() { _gwt_cmd remove "$@"; }

gwt-cleanup-merged() { _gwt_cmd cleanup "$@"; }

gwt-push() { _gwt_cmd push "$@"; }

gwt-status() { _gwt_cmd status "$@"; }

gwt-from-pr() { _gwt_cmd from-pr "$@"; }

if [[ -n "$BASH_VERSION" ]]; then
    eval "$(command "$_gwt_cli" completion bash)"
elif [[ -n "$ZSH_VERSION" ]]; then
    eval "$(command "$_gwt_cli" completion zsh)"
fi

unset -f _gwt_cmd
unset _gwt_cli
