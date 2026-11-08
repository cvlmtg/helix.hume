#!/usr/bin/env bash
# w/e/b and their WORD forms select from a lone bare cursor as Helix's do,
# then move word by word; several cursors take whole words.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

# w: the rest of the word and the space after it, then the next word.
expect default.scm $'foo bar baz\n' "lwd" $'fbar baz\n'
expect default.scm $'foo bar baz\n' "lwwd" $'foo baz\n'

# e: the rest of the word, then each next word with the space before it.
expect default.scm $'foo bar baz\n' "led" $'f bar baz\n'
expect default.scm $'foo bar baz\n' "leed" $'foo baz\n'
expect default.scm $'foo bar baz\n' "leeed" $'foo bar\n'

# e on a word's last character goes to the next word.
expect default.scm $'foo bar\n' "lled" $'foo\n'

# b: from the cursor back to the word's start, the head on the start.
expect default.scm $'foo bar\n' "lllllbd" $'foo r\n'
expect default.scm $'foo bar\n' "lllllb;iX<esc>" $'foo Xbar\n'

# b on a word's first character, and b again, select each previous word.
expect default.scm $'foo bar\n' "llllbd" $'bar\n'
expect default.scm $'foo bar\n' "llllb;iX<esc>" $'Xfoo bar\n'
expect default.scm $'foo bar baz\n' "lllllllllbbd" $'foo baz\n'
expect default.scm $'foo bar baz\n' "lllllllllbbbd" $'bar baz\n'

# The cursor walk steps a cluster at a time, over a combining mark too.
expect default.scm $'cafés x\n' "llllwd" $'caféx\n'

# A count goes straight to the next word.
expect default.scm $'foo bar baz\n' "l1wd" $'foo baz\n'

# Several cursors each take their whole word.
expect default.scm $'foo\nbar\n' "lCed" $'\n\n'

# W, E and B work on whitespace-delimited WORDs.
expect default.scm $'a.b c.d e\n' "lWd" $'ac.d e\n'
expect default.scm $'a.b c.d e\n' "lEEd" $'a.b e\n'
expect default.scm $'a.b c.d\n' "lllllBd" $'a.b d\n'

# On whitespace, w selects the rest of the whitespace run and e runs on
# through the next word's end.
expect default.scm $'foo   bar\n' "lllwd" $'foobar\n'
expect default.scm $'foo   bar\n' "llllwd" $'foo bar\n'
expect default.scm $'foo   bar baz\n' "llled" $'foo baz\n'
expect default.scm $'a.b   c.d\n' "lllWd" $'a.bc.d\n'
expect default.scm $'a.b   c.d\n' "lllEd" $'a.b\n'
