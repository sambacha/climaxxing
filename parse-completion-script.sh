#!/bin/bash

parse_completion_script() {
    local script_file="$1"
    local tool_name=$(grep "complete -F" "$script_file" | awk '{print $NF}')
    
    echo "Tool: $tool_name"
    echo "Subcommands:"
    grep -oP '(?<=compgen -W ")[^"]*' "$script_file" | tr ' ' '\n' | sort -u | grep -v -- '--'
    
    echo "Options:"
    grep -oP '(?<=compgen -W ")[^"]*' "$script_file" | tr ' ' '\n' | sort -u | grep -- '--'
}

parse_completion_script "bash_completion_script.sh"
