#!/bin/bash
set -e

if ! xcrun --find mcpbridge &>/dev/null; then
    echo "❌ Xcode is required to run mcpbridge"
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo -e "Usage: sbxrun.sh <agent> [sandbox name]"
    exit 1
fi

AGENT=$1
NAME=${2:-calendr-$AGENT}

if [[ "$AGENT_KIT" == "" ]]; then

    if [[ $AGENT == "pi" ]]; then
        AGENT_KIT="./sandbox/kit/pi-kit"
    fi

fi

SBX_ENV_LOCAL="sbxenv.local.yaml"

if [ ! -f "sbxenv.local.yaml" ]; then
    unset SBX_ENV_LOCAL
fi

# `sbx env run` creates and launches the agent,
# but it breaks the clipboard, for some reason.

sbx env run \
    --detach \
    --force \
    --env-arg home="$HOME" \
    --env-arg agent="$AGENT" \
    --env-arg name="$NAME" \
    --env-arg agent-kit="$AGENT_KIT" \
    sbxenv.yaml $SBX_ENV_LOCAL

# This is to avoid losing the previous output when attaching to the sandbox.
# If an MCP fails to load, it's just a warning, so it doesn't stop the script.
printf "\nPress [Enter] to continue or [Esc] to abort..."

read -r -s -n 1 char

if [[ "$char" == $'\e' ]]; then
    exit 1
fi

sbx exec -it "$NAME" "$AGENT"
