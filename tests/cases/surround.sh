#!/usr/bin/env bash
# m s wraps, m d deletes a pair, m r replaces one; m w surrounds nothing.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect default.scm $'hello\n' "ems(" $'(hello)\n'
expect default.scm $'(hello)\n' "llmd(" $'hello\n'
expect default.scm $'(hello)\n' "llmr([" $'[hello]\n'
expect default.scm $'(hello)\n' "llmdq" $'(hello)\n'
expect default.scm $'hello\n' "emw(" $'hello\n'

# m d is not repeatable itself: . repeats the delete its callback ran, on the
# pair around the cursor it is pressed on.
expect default.scm $'(hello) (world)\n' "llmd(fr;." $'hello world\n'
