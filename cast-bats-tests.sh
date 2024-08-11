#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-mock/src/bats-mock'

setup() {
    export CAST_MOCK="$BATS_TEST_DIRNAME/cast_mock"
    export PATH="$BATS_TEST_DIRNAME:$PATH"
}

teardown() {
    rm -f "$CAST_MOCK"
}

# Helper function to parse the completion script
parse_completion_script() {
    local script_file="$1"
    local current_command=""
    declare -A commands

    while IFS= read -r line; do
        if [[ "$line" == cast\)* ]]; then
            current_command="cast"
            commands["$current_command"]=""
        elif [[ "$line" == cast__*\)* ]]; then
            current_command=$(echo "$line" | sed 's/cast__\(.*\)).*/\1/' | tr '_' ' ')
            commands["$current_command"]=""
        elif [[ "$line" == *opts=* && -n "$current_command" ]]; then
            options=$(echo "$line" | grep -o -- '-[a-zA-Z0-9-]*' | tr '\n' ' ')
            commands["$current_command"]+="$options"
        fi
    done < "$script_file"

    echo "$(declare -p commands)"
}

# Generate test cases
generate_test_cases() {
    local -n cmds=$1
    for cmd in "${!cmds[@]}"; do
        local options="${cmds[$cmd]}"
        echo "@test \"Test completion for 'cast $cmd'\" {"
        echo "    mock_set_output \"$CAST_MOCK\" \"$options\""
        echo "    run cast $cmd --generate-bash-completion"
        echo "    assert_success"
        echo "    assert_output --partial \"$options\""
        echo "}"
        echo
        # Generate incremental stubbing tests
        local option_array=($options)
        for ((i=0; i<${#option_array[@]}; i++)); do
            local partial_options="${option_array[@]:0:$i+1}"
            echo "@test \"Test incremental completion for 'cast $cmd' (${i+1} options)\" {"
            echo "    mock_set_output \"$CAST_MOCK\" \"$partial_options\""
            echo "    run cast $cmd --generate-bash-completion"
            echo "    assert_success"
            echo "    assert_output --partial \"$partial_options\""
            echo "}"
            echo
        done
    done
}

# Main test generation
@test "Generate and run cast completion tests" {
    # Parse the completion script
    eval "$(parse_completion_script "$BATS_TEST_DIRNAME/cast.d")"

    # Generate test cases
    test_cases=$(generate_test_cases commands)

    # Write test cases to a temporary file
    echo "$test_cases" > "$BATS_TEST_DIRNAME/temp_tests.bats"

    # Run the generated tests
    run bats "$BATS_TEST_DIRNAME/temp_tests.bats"

    # Clean up
    rm "$BATS_TEST_DIRNAME/temp_tests.bats"

    # Assert that all tests passed
    assert_success
}

# Test for invalid input
@test "Test completion for invalid input" {
    run cast invalid-command --generate-bash-completion
    assert_failure
    assert_output --partial "invalid-command: command not found"
}

# Test for partial input
@test "Test completion for partial input 'cast to-'" {
    mock_set_output "$CAST_MOCK" "to-hex to-wei to-unit"
    run cast to- --generate-bash-completion
    assert_success
    assert_output --partial "to-hex to-wei to-unit"
}
