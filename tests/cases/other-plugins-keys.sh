#!/usr/bin/env bash
# Keys for another plugin's commands run them when that plugin's commands
# exist at load, and stay unbound otherwise.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

bindings=(
    " f|pickers/files"
    " F|pickers/files"
    " b|pickers/buffers"
    " g|pickers/git-modified"
    " k|lsp/hover"
    " s|lsp/document-symbols"
    " S|lsp/workspace-symbols"
    " r|lsp/rename"
    " a|lsp/code-actions"
    " p|classic-paste/clipboard-after"
    " P|classic-paste/clipboard-before"
    "gr|lsp/references"
    "=|lsp/format-source"
    "]d|lsp/goto-next-diagnostic"
    "[d|lsp/goto-prev-diagnostic"
)

for binding in "${bindings[@]}"; do
    keys="${binding%%|*}"
    command="${binding#*|}"
    expect stand-ins.scm $'foo\n' "$keys" "${command}foo"$'\n'
    expect default.scm $'foo\n' "$keys" $'foo\n'
done
