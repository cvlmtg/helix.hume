#!/usr/bin/env bash
# g t / g c / g b go to the top, center and bottom of the view, g j / g k move
# by buffer lines, and X extends selections to whole lines.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

# A headless view shows 24 lines and keeps the default scroll-margin of 3.
lines="$(seq 1 100)"$'\n'
marked() { printf '%s\n' "$lines" | sed "$1s/^/X/"; }

expect default.scm "$lines" "gtiX<esc>" "$(marked 4)"$'\n'
expect default.scm "$lines" "2gtiX<esc>" "$(marked 5)"$'\n'
expect default.scm "$lines" "gciX<esc>" "$(marked 12)"$'\n'
expect default.scm "$lines" "gbiX<esc>" "$(marked 21)"$'\n'
expect default.scm "$lines" "vgtd" "$(printf '%s\n' "$lines" | sed '1,3d; 4s/^.//')"$'\n'

# g j moves down a buffer line where j moves down a wrapped line's rows.
long="$(printf 'a%.0s' $(seq 1 200))"
expect default.scm "$long"$'\nzz\n' "gjiQ<esc>" "$long"$'\nQzz\n'
expect default.scm $'a\nb\n' "jgkiQ<esc>" $'Qa\nb\n'

# X takes whole lines, keeps a whole-line selection, and keeps the
# selection's direction.
expect default.scm $'foo bar\nbaz\n' "llXd" $'baz\n'
expect default.scm $'a\nb\nc\n' "xXd" $'b\nc\n'
expect default.scm $'foo bar\nbaz qux\nend\n' "jlllvkX<esc>;iZ<esc>" $'Zfoo bar\nbaz qux\nend\n'
