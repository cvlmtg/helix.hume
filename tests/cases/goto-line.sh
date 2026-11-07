#!/usr/bin/env bash
# g g goes to the first line, or to the line a count names, clamped to the
# last one.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect default.scm $'foo\nbar\nbaz\n' "jjggiX<esc>" $'Xfoo\nbar\nbaz\n'
expect default.scm $'foo\nbar\nbaz\n' "2ggiX<esc>" $'foo\nXbar\nbaz\n'
expect default.scm $'foo\nbar\nbaz\n' "9ggiX<esc>" $'foo\nbar\nXbaz\n'
