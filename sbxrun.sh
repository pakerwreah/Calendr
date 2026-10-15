#!/bin/bash
set -e

if ! xcrun --find mcpbridge &>/dev/null; then
    echo "❌ Xcode is required to run mcpbridge"
    exit 1
fi

if [[ $# -eq 0 ]] ; then
    echo -e "❌ Missing agent name\n"
    sbx run --help | grep agents
    exit 1
fi

AGENT=$1
NAME=${2:-calendr-$AGENT}

# `sbx env run` creates and launches the agent,
# but it breaks the clipboard, for some reason.

sbx env run \
    --detach \
    --force \
    --env-arg name="$NAME" \
    --env-arg agent="$AGENT"

sbx exec -it "$NAME" "$AGENT"
