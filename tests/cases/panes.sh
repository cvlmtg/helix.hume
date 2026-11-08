#!/usr/bin/env bash
# Ctrl-w o and Space w o close every pane but the focused one.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect probes.scm $'foo\n' "<c-w>v<c-w>s<c-w>v<c-t>" $'4foo\n'
expect probes.scm $'foo\n' "<c-w>v<c-w>s<c-w>v<c-w>o<c-t>" $'1foo\n'
expect probes.scm $'foo\n' "<c-w>v<c-w>s<c-w><c-o><c-t>" $'1foo\n'
expect probes.scm $'foo\n' "<c-w>v wo<c-t>" $'1foo\n'
expect probes.scm $'foo\n' "<c-w>o<c-t>" $'1foo\n'
