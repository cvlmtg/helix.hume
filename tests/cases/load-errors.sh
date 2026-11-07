#!/usr/bin/env bash
# On an editor older than the supported version, or without core:stdlib, the
# plugin refuses to load and names itself and what it needs.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
source ./lib.sh

expect_log old-hume.scm "$PLUGIN_NAME: requires HUME $MIN_HUME_VERSION or later"
expect_log no-stdlib.scm "$PLUGIN_NAME: requires core:stdlib"
