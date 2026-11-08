#!/usr/bin/env bash
# ! and Alt-! run a shell command once and insert its output before or after
# each selection, selecting it; a failing command changes nothing.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect default.scm $'foo bar\n' "e!echo hi<ret>" $'hifoo bar\n'
expect default.scm $'foo bar\n' "e<a-!>echo hi<ret>" $'foohi bar\n'
expect default.scm $'foo bar\n' "e<a-!>echo hi<ret>d" $'foo bar\n'
expect default.scm $'foo bar\n' "%s\\w+<ret>!printf ab<ret>" $'abfoo abbar\n'
expect default.scm $'foo bar\n' "e!false<ret>" $'foo bar\n'
expect default.scm $'foo bar\n' "e!echo hi<ret>u" $'foo bar\n'
