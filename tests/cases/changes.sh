#!/usr/bin/env bash
# ] g / [ g select the next and previous change against git's HEAD, ] G / [ G
# the last and first; ] D / [ D and Space d / D do nothing without
# diagnostics.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

base=$'a\nb\nc\nd\ne\n'
edited=$'a\nB\nc\nd\nE\n'

expect_git default.scm "$base" "$edited" "]gd" $'a\nc\nd\nE\n'
expect_git default.scm "$base" "$edited" "]g]gd" $'a\nB\nc\nd\n'
expect_git default.scm "$base" "$edited" "2]gd" $'a\nB\nc\nd\n'
expect_git default.scm "$base" "$edited" "]Gd" $'a\nB\nc\nd\n'
expect_git default.scm "$base" "$edited" "4gg[gd" $'a\nc\nd\nE\n'
expect_git default.scm "$base" "$edited" "4gg[Gd" $'a\nc\nd\nE\n'

# A hunk of several lines is selected whole; a removed line gives a cursor
# where it was.
expect_git default.scm $'a\nb\nc\n' $'a\nX\nY\nc\n' "]gd" $'a\nc\n'
expect_git default.scm $'a\nb\nc\n' $'a\nc\n' "]giZ<esc>" $'a\nZc\n'

# With no git base or no change, the cursor stays.
expect default.scm $'a\nb\n' "]giZ<esc>" $'Za\nb\n'
expect_git default.scm $'a\nb\n' $'a\nb\n' "]giZ<esc>" $'Za\nb\n'

expect default.scm $'a\nb\n' "j]DiZ<esc>" $'a\nZb\n'
expect default.scm $'a\nb\n' "j[DiZ<esc>" $'a\nZb\n'
expect default.scm $'a\nb\n' " diZ<esc>" $'Za\nb\n'
expect default.scm $'a\nb\n' " DiZ<esc>" $'Za\nb\n'
