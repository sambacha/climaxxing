#!/bin/bash

# Source the parse_completion_script function
source parse_completion_script.sh

# Source the generate_test_cases function
source generate_test_cases.sh

# Main function
main() {
    local completion_script="$1"
    local output_test_script="$2"

    # Parse the completion script
    local tool_info=$(parse_completion_script "$completion_script")
    local tool_name=$(echo "$tool_info" | grep "Tool:" | cut -d' ' -f2)
    local subcommands=($(echo "$tool_info" | sed -n '/Subcommands:/,/Options:/p' | tail -n +2 | head -n -1))

    # Generate test cases
    generate_test_cases "$tool_name" "${subcommands[@]}" > "$output_test_script"

    echo "Test script generated: $output_test_script"
}

# Check if the required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <completion_script> <output_test_script>"
    exit 1
fi

main "$1" "$2"
