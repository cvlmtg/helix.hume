#!/usr/bin/env bash
# invariants this repo documents that only this script enforces:
# - README's Requirements version, plugin.scm's load-time version check and
#   its error message all match tests/lib.sh's MIN_HUME_VERSION
# - every top-level define and every command name uses this plugin's prefix
# - no tabs or trailing whitespace in a .scm file.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

PREFIX="helix/"

fail=0
note() {
    echo "lint: $1" >&2
    fail=1
}

# --- README's Requirements version vs tests/lib.sh's MIN_HUME_VERSION ------
min_version="$(grep -oE '^MIN_HUME_VERSION="[^"]*"' tests/lib.sh | grep -oE '"[^"]*"' | tr -d '"')"
readme_version="$(grep -oE '^- HUME [0-9]+\.[0-9]+\.[0-9]+ or later\.' README.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)"
if [[ "$min_version" != "$readme_version" ]]; then
    note "README Requirements says HUME $readme_version, but tests/lib.sh's MIN_HUME_VERSION is $min_version"
fi

# --- plugin.scm's load-time version check vs MIN_HUME_VERSION ---------------
check_version="$(grep -oE '\(hume-version>=\? [0-9]+ [0-9]+ [0-9]+\)' plugin.scm \
    | grep -oE '[0-9]+ [0-9]+ [0-9]+' | tr ' ' '.' || true)"
if [[ "$min_version" != "$check_version" ]]; then
    note "plugin.scm checks (hume-version>=? ${check_version//./ }), but tests/lib.sh's MIN_HUME_VERSION is $min_version"
fi
message_version="$(grep -oE 'requires HUME [0-9]+\.[0-9]+\.[0-9]+ or later' plugin.scm \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)"
if [[ "$min_version" != "$message_version" ]]; then
    note "plugin.scm's error says HUME $message_version, but tests/lib.sh's MIN_HUME_VERSION is $min_version"
fi

# --- every top-level define uses $PREFIX ------------------------------------
# Matches both (define name ...) and the (define (name args) ...) shorthand.
bad_defines="$(grep -oE '^\(define[[:space:]]+\(?[a-zA-Z0-9!?*/<>=+-]+' plugin.scm \
    | grep -oE '[a-zA-Z0-9!?*/<>=+-]+$' \
    | grep -v "^${PREFIX}" || true)"
for name in $bad_defines; do
    note "plugin.scm: top-level define \"$name\" doesn't start with \"$PREFIX\" (CONTRIBUTING.md's naming convention)"
done

# --- every command name uses $PREFIX -----------------------------------------
bad_commands="$(grep -oE '\(define-command! "[^"]+"' plugin.scm \
    | grep -oE '"[^"]+"' | tr -d '"' \
    | grep -v "^${PREFIX}" || true)"
for name in $bad_commands; do
    note "plugin.scm: command \"$name\" doesn't start with \"$PREFIX\""
done

# --- whitespace hygiene in .scm files ---------------------------------------
tab="$(printf '\t')"
while IFS= read -r -d '' file; do
    if grep -q "$tab" "$file"; then
        note "$file: contains a tab"
    fi
    if grep -qE ' +$' "$file"; then
        note "$file: has trailing whitespace"
    fi
done < <(find . -name '*.scm' -not -path './.git/*' -print0)

if [[ "$fail" -eq 0 ]]; then
    echo "lint: clean"
else
    exit 1
fi
