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

# Alt-c changes the selection without putting it on the kill ring, which R
# then still reads.
expect default.scm $'foo bar baz\n' "edle<a-c>Z<esc>" $' Z baz\n'
expect default.scm $'foo bar baz\n' "edle<a-c>Z<esc>R" $' foo baz\n'

# Insert mode: PageDown pages as it does in Normal mode.
lines="$(seq 1 100)"$'\n'
run_hume default.scm "$lines" "<pagedown>iQ<esc>"
expect default.scm "$lines" "i<pagedown>Q<esc>" "$OUTPUT"

# Insert mode: Ctrl-u deletes back to the first non-blank, or to the line
# start from there, or joins the line above from the line start; Ctrl-k
# deletes to the line end, or joins the next line from there.
expect default.scm $'    foo bar\n' "A<c-u><esc>" $'    \n'
expect default.scm $'    foo\n' "llllix<c-h><c-u><esc>" $'foo\n'
expect default.scm $'a\nb\n' "ji<c-u><esc>" $'ab\n'
expect default.scm $'foo bar\n' "lli<c-k><esc>" $'fo\n'
expect default.scm $'foo\nbar\n' "A<c-k><esc>" $'foobar\n'

# Insert mode: Alt-d deletes to the end of the next word, a run of
# punctuation counting as one.
expect default.scm $'foo bar baz\n' "i<a-d><esc>" $' bar baz\n'
expect default.scm $'foo bar baz\n' "llli<a-d><esc>" $'foo baz\n'
expect default.scm $'foo.bar\n' "i<a-d><a-d><esc>" $'bar\n'

# The : prompt: Ctrl-s inserts the word under the cursor.
expect probes.scm $'foo bar\n' ":test-insert <c-s><ret>" $'foofoo bar\n'
