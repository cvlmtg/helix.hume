#!/usr/bin/env bash
# tests/lib.sh — headless driver shared by run.sh and every tests/cases/*.sh.
#
# Every check runs `hume --keys` once: HUME opens an input file, replays a key
# stream with this working copy loaded as the installed plugin, and writes the
# buffer to an output file the check compares byte for byte. A motion is
# checked through the edit that follows it (`w` then `d` deletes what `w`
# selected). Each run gets its own throwaway $XDG_DATA_HOME, so a check never
# touches the real ~/.config/hume or ~/.local/share/hume.
#
# A case script sources this file and calls `expect`/`expect_log`; `set -e`
# (set below) turns a failed check into a non-zero exit, which run.sh reads
# as the case failing.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/tests/config"

PLUGIN_NAME="cvlmtg/helix.hume"
MIN_HUME_VERSION="0.19.0" # keep in step with README's Requirements section and plugin.scm's load-time check

# ── Resolving which `hume` to drive ─────────────────────────────────────────
#
# Order: an explicit $HUME_BIN override, then $HUME_REPO (explicit), then
# `hume` on PATH (the default, which CI uses), then a sibling checkout at
# ../hume for a dev machine with both repos side by side but no installed
# `hume`. Resolves to a PATH-prepended shim so every case invokes `hume`
# the same way.
#
# Called once by run.sh, never by a case script: the resolved PATH is
# inherited by every case subprocess, so cargo builds once.
hume_resolve() {
    local shim_dir bin runtime=""
    shim_dir="$(mktemp -d)"
    trap "rm -rf '$shim_dir'" EXIT # single quotes would defer expansion past hume_resolve's own scope

    if [[ -n "${HUME_BIN:-}" ]]; then
        bin="$HUME_BIN"
    elif [[ -n "${HUME_REPO:-}" ]]; then
        echo "tests: building hume from \$HUME_REPO ($HUME_REPO)..." >&2
        (cd "$HUME_REPO" && cargo build -p hume-editor) >&2
        bin="${CARGO_TARGET_DIR:-$HUME_REPO/target}/debug/hume"
        runtime="$HUME_REPO/runtime"
    elif command -v hume >/dev/null 2>&1; then
        bin="$(command -v hume)"
    elif [[ -d "$REPO_ROOT/../hume" ]]; then
        local checkout="$REPO_ROOT/../hume"
        echo "tests: building hume from sibling checkout ($checkout)..." >&2
        (cd "$checkout" && cargo build -p hume-editor) >&2
        bin="${CARGO_TARGET_DIR:-$checkout/target}/debug/hume"
        runtime="$checkout/runtime"
    else
        echo "tests: no hume found — set \$HUME_BIN, set \$HUME_REPO, put hume on PATH, or check out cvlmtg/hume next to this repo" >&2
        exit 1
    fi

    cat > "$shim_dir/hume" <<SHIM
#!/usr/bin/env bash
$([[ -n "$runtime" ]] && echo "export HUME_RUNTIME=\"$runtime\"")
exec "$bin" "\$@"
SHIM
    chmod +x "$shim_dir/hume"
    export PATH="$shim_dir:$PATH"

    _hume_check_version "$bin"
}

# _hume_check_version <bin> — aborts with a clear message if <bin> reports
# an older version than $MIN_HUME_VERSION, instead of letting an
# unsupported binary fail every case in confusing ways.
_hume_check_version() {
    local bin="$1" raw version oldest
    raw="$("$bin" --version)"      # "hume 0.19.0-6cf710e4"
    version="${raw#* }"            # "0.19.0-6cf710e4"
    version="${version%%-*}"       # "0.19.0": strip a nightly's commit suffix
    oldest="$(printf '%s\n%s\n' "$version" "$MIN_HUME_VERSION" | sort -V | head -1)"
    if [[ "$oldest" != "$MIN_HUME_VERSION" ]]; then
        echo "tests: $bin is $raw, but these tests need hume $MIN_HUME_VERSION or later" >&2
        exit 1
    fi
}

# ── One headless run ─────────────────────────────────────────────────────────

# run_hume <config> <input> <keys> [<base>]
#
# Runs hume on a file holding <input>, with tests/config/<config> (its
# @PLUGIN@ replaced by $PLUGIN_NAME) as init.scm, replaying <keys> in HUME's
# key-stream notation (`<esc>`, `<ret>`, `<c-h>`, `<a-.>`; a space is a
# space). With <base>, the file sits in a git repository whose HEAD holds
# <base> as its committed text. Sets OUTPUT to the buffer it saved and LOG to
# its messages, trace lines left out.
run_hume() {
    local config="$1" input="$2" keys="$3" work
    work="$(mktemp -d)"
    mkdir -p "$work/data/hume/plugins/${PLUGIN_NAME%/*}"
    ln -s "$REPO_ROOT" "$work/data/hume/plugins/$PLUGIN_NAME"
    sed -e "s|@PLUGIN@|$PLUGIN_NAME|g" "$CONFIG_DIR/$config" > "$work/init.scm"
    if [[ "$#" -ge 4 ]]; then
        printf '%s' "$4" > "$work/input.txt"
        git -C "$work" init -q
        git -C "$work" add input.txt
        git -C "$work" -c user.name=tests -c user.email=tests@localhost \
            -c commit.gpgsign=false commit -q -m base
    fi
    printf '%s' "$input" > "$work/input.txt"

    XDG_DATA_HOME="$work/data" hume --config "$work/init.scm" --keys "$keys" \
        --output "$work/output.txt" "$work/input.txt" 2> "$work/log.txt" || true

    OUTPUT="$(cat "$work/output.txt" 2>/dev/null; echo x)"
    OUTPUT="${OUTPUT%x}" # the x keeps $(...) from stripping the trailing newlines
    LOG="$(grep -v '^hume: trace:' "$work/log.txt" || true)"
    rm -rf "$work"
}

# _check_output <input> <keys> <expected-output> — fails, printing both
# texts and the log, when the buffer the last run_hume saved differs.
_check_output() {
    if [[ "$OUTPUT" != "$3" ]]; then
        echo "keys:     $(printf '%q' "$2")" >&2
        echo "input:    $(printf '%q' "$1")" >&2
        echo "expected: $(printf '%q' "$3")" >&2
        echo "got:      $(printf '%q' "$OUTPUT")" >&2
        [[ -n "$LOG" ]] && echo "log:"$'\n'"$LOG" >&2
        return 1
    fi
}

# expect <config> <input> <keys> <expected-output>
#
# Fails, printing both texts and the log, when the saved buffer differs.
expect() {
    run_hume "$1" "$2" "$3"
    _check_output "$2" "$3" "$4"
}

# expect_git <config> <base> <input> <keys> <expected-output>
#
# Like expect, with the file committed as <base> in a git repository.
expect_git() {
    run_hume "$1" "$3" "$4" "$2"
    _check_output "$3" "$4" "$5"
}

# expect_log <config> <substring> — fails unless loading <config> logs a
# message containing <substring>. An empty <substring> instead requires a
# log with no message at all.
expect_log() {
    run_hume "$1" $'x\n' ""
    if [[ -z "$2" ]]; then
        if [[ -n "$LOG" ]]; then
            echo "expected no messages, got:"$'\n'"$LOG" >&2
            return 1
        fi
    elif [[ "$LOG" != *"$2"* ]]; then
        echo "expected a message containing: $2" >&2
        echo "log:"$'\n'"$LOG" >&2
        return 1
    fi
}
