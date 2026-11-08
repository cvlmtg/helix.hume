#!/usr/bin/env bash
# Helix's typed commands that HUME doesn't have. A run works in tests/, so a
# relative path names a file there, and `%` names the run's own file.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

# :open / :o, with a :line suffix; a missing file opens empty.
expect default.scm $'a\n' ":o other.txt<ret>iX<esc>" $'X\n'
expect default.scm $'a\n' ":open config/no-stdlib.scm:2<ret>iX<esc>" "$(sed '2s/^/X/' config/no-stdlib.scm)"$'\n'

# :buffer-close / :bc keeps a modified buffer unless forced; the others and
# all forms close the rest. Closing the last buffer leaves a scratch one.
expect default.scm $'a\n' "iY<esc>:bc<ret>iX<esc>" $'XYa\n'
expect default.scm $'a\n' "iY<esc>:bc!<ret>iX<esc>" $'X\n'
expect default.scm $'a\n' ":bclose<ret>iX<esc>" $'X\n'
expect default.scm $'a\n' ":e other.txt<ret>:bco<ret>:bn<ret>iX<esc>" $'X\n'
expect default.scm $'a\n' ":e other.txt<ret>:bca<ret>:bn<ret>iX<esc>" $'X\n'
expect default.scm $'a\n' "iY<esc>:e other.txt<ret>:bca<ret>:bn<ret>iX<esc>" $'XYa\n'
expect default.scm $'a\n' ":e other.txt<ret>:buffer-next<ret>iX<esc>" $'Xa\n'
expect default.scm $'a\n' ":e other.txt<ret>:buffer-previous<ret>iX<esc>" $'Xa\n'

# :hsplit / :hs / :vs split, and open their paths in the split; the -new
# forms split onto a scratch buffer.
expect probes.scm $'a\n' ":hs<ret><c-t>" $'2a\n'
expect probes.scm $'a\n' ":vs<ret><c-t>" $'2a\n'
expect probes.scm $'a\n' ":hsplit other.txt<ret>iX<esc>" $'X\n'
expect probes.scm $'a\n' ":vnew<ret>iX<esc>" $'X\n'
expect probes.scm $'a\n' ":hnew<ret><c-t>" $'2\n'

# :g goes to a line.
expect default.scm $'a\nb\nc\n' ":g 2<ret>iX<esc>" $'a\nXb\nc\n'

# :yank-join joins the selections into one yank, by default with a line
# break; R then pastes it over each selection.
expect default.scm $'a b\n' "%s\\w+<ret>:yank-join -<ret>R" $'a-b a-b\n'
expect default.scm $'a b\n' "%s\\w+<ret>:yank-join<ret>R" $'a\nb a\nb\n'

# :insert-output / :append-output run a command as ! and Alt-! do.
expect default.scm $'foo bar\n' "e:insert-output echo hi<ret>" $'hifoo bar\n'
expect default.scm $'foo bar\n' "e:append-output echo hi<ret>" $'foohi bar\n'

# :read / :r inserts a file at the cursor.
expect default.scm $'ab\n' ":r %<ret>" $'ab\nab\n'

# :reflow wraps to a width, keeping the first line's indent and comment
# marker on every line and blank lines between paragraphs.
expect default.scm $'aaa bbb ccc ddd\n' "%:reflow 8<ret>" $'aaa bbb\nccc ddd\n'
expect default.scm $'  # aaa bbb ccc\n' "%:reflow 12<ret>" $'  # aaa bbb\n  # ccc\n'
expect default.scm $'a b\n\nc d\n' "%:reflow 1<ret>" $'a\nb\n\nc\nd\n'

# :diffget / :reset-diff-change put the committed lines back.
expect_git default.scm $'a\nb\nc\n' $'a\nX\nc\n' "j:diffget<ret>" $'a\nb\nc\n'
expect_git default.scm $'a\nb\nc\n' $'a\nc\n' "j:reset-diff-change<ret>" $'a\nb\nc\n'
expect_git default.scm $'a\nb\nc\nd\n' $'a\nX\nc\nY\n' "j:diffg<ret>" $'a\nb\nc\nY\n'

# :indent-style sets what Tab inserts; :toggle cycles an option through the
# values given.
expect default.scm $'a\n' ":indent-style 2<ret>i<tab>X<esc>" $'  Xa\n'
expect default.scm $'a\n' ":indent-style 2<ret>:indent-style t<ret>i<tab>X<esc>" $'\tXa\n'
expect default.scm $'a\n' ":toggle indent-style hard soft<ret>i<tab>X<esc>" $'    Xa\n'
expect default.scm $'\n' "i(<esc>" $'()\n'
expect default.scm $'\n' ":toggle insert-auto-pairs<ret>i(<esc>" $'(\n'

# :line-ending sets the line ending the buffer is written with.
expect probes.scm $'a\n' ":line-ending crlf<ret>:test-option line-ending<ret>" $'crlfa\n'
expect probes.scm $'a\n' ":line-ending crlf<ret>:line-ending lf<ret>:test-option line-ending<ret>" $'lfa\n'

# :lang sets the language, here checked through its comment token.
expect default.scm $'a\n' ":lang rust<ret> c" $'// a\n'
expect default.scm $'a\n' ":lang rust<ret>:lang text<ret> c" $'a\n'

# :change-current-directory moves where relative paths start, and - goes
# back.
expect default.scm $'a\n' ":change-current-directory config<ret>:r no-stdlib.scm<ret>" "$(cat config/no-stdlib.scm)"$'\na\n'
expect default.scm $'a\n' ":change-current-directory config<ret>:change-current-directory -<ret>:r config/no-stdlib.scm<ret>" "$(cat config/no-stdlib.scm)"$'\na\n'
