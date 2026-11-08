#!/usr/bin/env bash
# HUME keys Helix doesn't have do nothing, and G goes to the line a count
# names. Each check would change the buffer if its key still ran HUME's
# command.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

text=$'ab cd\nef gh\nij kl\n'
at_cursor=$'ab cd\neXf gh\nij kl\n'

# # (matching bracket), { (previous paragraph), S (split on newlines).
expect default.scm $'(ab)\n' "#iX<esc>" $'X(ab)\n'
expect default.scm $'a\n\nb\n' "jj{iX<esc>" $'a\n\nXb\n'
expect default.scm $'a\nb\n' "%SiX<esc>" $'Xa\nb\n'

# Ctrl-p v (vertical split): the probe pastes the pane count.
expect probes.scm "$text" "<c-p>v<c-t>" "1$text"

# m / (select every match), m u (selection undo), M M (WORD), m i i (last
# insertion), m i l (line).
expect default.scm $'ab ab\n' "/b<ret>m/iX<esc>" $'aXb ab\n'
expect default.scm "$text" "%s\\w+<ret>muiX<esc>" $'Xab Xcd\nXef Xgh\nXij Xkl\n'
expect default.scm "$text" "jlMMiX<esc>" "$at_cursor"
expect default.scm $'ab\n' "iY<esc>lmiiiX<esc>" $'YXab\n'
expect default.scm "$text" "jlmiliX<esc>" "$at_cursor"

# Ctrl-e (flip), Ctrl-r (redo), Ctrl-s (decrement), Ctrl-Shift-x (line
# backward), G U (uppercase).
expect default.scm "$text" "jlvl<esc><c-e>;iX<esc>" $'ab cd\nefX gh\nij kl\n'
expect default.scm "$text" "jliY<esc>u<c-r>" "$text"
expect default.scm $'5\n' "<c-s>" $'5\n'
expect default.scm "$text" "jl<c-X>iX<esc>" "$at_cursor"
expect default.scm "$text" "jlGUiX<esc>" "$at_cursor"

# core:pickers' z f / z m open no picker; core:classic-paste's Ctrl-v pastes
# nothing.
expect core-plugins.scm "$text" "jlzfiX<esc>" "$at_cursor"
expect core-plugins.scm "$text" "jlzmiX<esc>" "$at_cursor"
expect core-plugins.scm "$text" "jl<c-v>iX<esc>" "$at_cursor"

# G goes to the line its count names, and does nothing without one, also
# once core:lsp has loaded and bound its own G keys.
expect default.scm "$text" "2GiX<esc>" $'ab cd\nXef gh\nij kl\n'
expect default.scm "$text" "jjGiX<esc>" $'ab cd\nef gh\nXij kl\n'
expect core-plugins.scm "$text" " k2GiX<esc>" $'ab cd\nXef gh\nij kl\n'
