#!/usr/bin/env bash
# Alt-u / Alt-U step through the undo history in the order it was made,
# across branches; g . goes back to the last change.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

# X, then Y, then an undo and Z on a new branch: three steps back reach the
# start, two forward reach Y's branch, which plain redo can't.
expect default.scm $'a\n' "iX<esc>iY<esc>uiZ<esc><a-u><a-u><a-u>" $'a\n'
expect default.scm $'a\n' "iX<esc>iY<esc>uiZ<esc><a-u><a-u><a-u><a-U><a-U>" $'YXa\n'
expect default.scm $'a\n' "iX<esc>2<a-u>" $'a\n'
expect default.scm $'a\n' "iX<esc><a-U>" $'Xa\n'

# g . goes to where the last change was made.
expect default.scm $'foo\nbar baz\nqux\n' "jwdggg.iX<esc>" $'foo\nXbaz\nqux\n'
expect default.scm $'foo\nbar\nqux\n' "jjlllaZ<esc>ggg.iX<esc>" $'foo\nbar\nquxXZ\n'
expect default.scm $'foo\n' "jg.iX<esc>" $'Xfoo\n'
