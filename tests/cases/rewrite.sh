#!/usr/bin/env bash
# R, ~ and Alt-( / Alt-) rewrite each selection in one undo step and select
# the new text.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

# R on a one-character selection replaces it, leaving the cursor on the last
# character of the replacement.
expect default.scm $'foo bar\n' "edlR" $' fooar\n'
expect default.scm $'foo bar\n' "edlR;iX<esc>" $' foXoar\n'

# R selects the replacement of a wider selection.
expect default.scm $'foo bar\n' "edleRd" $' \n'

# ~ swaps the case of each character and keeps the selection.
expect default.scm $'Foo bar\n' "e~" $'fOO bar\n'
expect default.scm $'Foo bar\n' "e~d" $' bar\n'
expect default.scm $'Foo bar\n' "e~u" $'Foo bar\n'
expect default.scm $'aB\nc\n' "%~" $'Ab\nC\n'

# Alt-) moves each selection's text to the next selection, Alt-( to the
# previous one, and each selection covers the text it received.
expect default.scm $'a bb ccc\n' "%s\\w+<ret><a-)>" $'ccc a bb\n'
expect default.scm $'a bb ccc\n' "%s\\w+<ret><a-(>" $'bb ccc a\n'
expect default.scm $'aa bbb cc\n' "%s\\w+<ret><a-)>d" $'  \n'
expect default.scm $'a bb ccc\n' "%s\\w+<ret><a-)>u" $'a bb ccc\n'
