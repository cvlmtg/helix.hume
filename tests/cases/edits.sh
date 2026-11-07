#!/usr/bin/env bash
# R, ] Space / [ Space, x, and the Insert-mode keys.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

# R replaces the selection with the last delete, in one undo step, and does
# nothing with the kill ring empty.
expect default.scm $'foo bar\n' "edleR" $' foo\n'
expect default.scm $'foo bar\n' "edleRu" $' bar\n'
expect default.scm $'foo bar\n' "eR" $'foo bar\n'

# ] Space / [ Space add blank lines below and above, as many as the count,
# one block per line whatever the number of selections on it.
expect default.scm $'foo\nbar\n' "ll] " $'foo\n\nbar\n'
expect default.scm $'foo\nbar\n' "ll] [ " $'\nfoo\n\nbar\n'
expect default.scm $'foo\n' "2] " $'foo\n\n\n'
expect default.scm $'foo\nbar\n' "%so<ret>] " $'foo\n\nbar\n'
expect default.scm $'x\nfoo\nbar\nbaz\n' "jvj] " $'x\nfoo\nbar\n\nbaz\n'
expect default.scm $'x\nfoo\nbar\nbaz\n' "jvj[ " $'x\n\nfoo\nbar\nbaz\n'

# x selects the line, then grows by a line on each press.
expect default.scm $'a\nb\nc\n' "xxd" $'c\n'

# Insert mode: Ctrl-h, Ctrl-d and Ctrl-j act as Backspace, Delete and Enter.
expect default.scm $'foo\n' "ixy<c-h><c-d><c-j><esc>" $'x\noo\n'
