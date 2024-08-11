#!/usr/bin/env bash

if [[ "$*" == *"--generate-bash-completion"* ]]; then
    cat "$CAST_MOCK"
else
    echo "cast $*"
fi
