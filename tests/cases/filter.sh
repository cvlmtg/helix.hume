#!/usr/bin/env bash
# K keeps the selections a regex matches inside, Alt-K removes them; neither
# leaves no selection.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect default.scm $'foo bar boo\n' "%s\\w+<ret>Ko<ret>d" $' bar \n'
expect default.scm $'foo bar boo\n' "%s\\w+<ret><a-K>o<ret>d" $'foo  boo\n'
expect default.scm $'foo bar boo\n' "%s\\w+<ret>Kbar<ret>d" $'foo  boo\n'

# The primary selection may be anywhere among the ones removed.
expect default.scm $'foo bar boo far\n' "%s\\w+<ret>))Ka<ret>d" $'foo  boo \n'

# With no match, K keeps every selection; with every selection matched,
# Alt-K leaves them all.
expect default.scm $'foo bar\n' "%s\\w+<ret>Kzzz<ret>d" $' \n'
expect default.scm $'foo boo\n' "%s\\w+<ret><a-K>o<ret>d" $' \n'
