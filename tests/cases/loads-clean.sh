#!/usr/bin/env bash
# The plugin loads with no message, alone and after the core plugins it binds
# keys for: every key it binds names a command that exists.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect_log default.scm ""
expect_log core-plugins.scm ""
