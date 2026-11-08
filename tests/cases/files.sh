#!/usr/bin/env bash
# g f opens the path under the cursor or the selected path, beside the
# buffer's own file; Ctrl-w f / F open it in a split; g m goes back to the
# last changed buffer. A run saves the focused buffer, so typing in the
# opened file shows which file it is.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect default.scm $'see other.txt now\n' "llllllgfiX<esc>" $'X\n'
expect default.scm $'other.txt\n' "%gfiX<esc>" $'X\n'
expect default.scm $'see other.txt now\n' "lllgfiX<esc>" $'seeX other.txt now\n'

expect probes.scm $'other.txt\n' "<c-w>fiX<esc>" $'X\n'
expect probes.scm $'other.txt\n' "<c-w>f<c-t>" $'2\n'
expect probes.scm $'other.txt\n' "<c-w>F<c-t>" $'2\n'

# g m returns to the changed buffer, and stays put when no other one changed.
expect default.scm $'x other.txt\n' "iA<esc>lllgfgm" $'Ax other.txt\n'
expect default.scm $'foo\n' "gmiX<esc>" $'Xfoo\n'
# A read-only view's refresh is not a change g m returns to.
expect probes.scm $'foo\n' "iA<esc><c-w>v<c-y><c-y><c-w>wgmiX<esc>" $'XAfoo\n'
