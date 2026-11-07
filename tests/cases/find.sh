#!/usr/bin/env bash
# f/t/F/T select from the cursor to the character they read; Extend mode
# grows the selection instead; Alt-. repeats the find.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect default.scm $'hello world\n' "llfwd" $'heorld\n'
expect default.scm $'hello world\n' "twd" $'world\n'
expect default.scm $'hello world\n' "llllllllllFod" $'hello w\n'
expect default.scm $'hello world\n' "llllllllllTod" $'hello wo\n'
expect default.scm $'a.b.c.d\n' "2f.d" $'c.d\n'
expect default.scm $'hello world\n' "vllfwd" $'orld\n'

# A cancelled read leaves the selection, here the cursor `d` then deletes.
expect default.scm $'hello world\n' "f<esc>d" $'ello world\n'

expect default.scm $'a.b.c\n' "f.<a-.>d" $'ac\n'
