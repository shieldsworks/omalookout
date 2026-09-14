#!/usr/bin/env bash
# Opens every vessel heard in a window of its own, from this checkout, in
# its own Quickshell process. Vessels come from omakeel, which must be
# running for any to show.
set -euo pipefail
cd "$(dirname "$0")"
exec quickshell -p ui/shell.qml "$@"
