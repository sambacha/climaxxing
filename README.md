# CLIMaxxing

> Ensure that your CLI tool's bash completion script is working correctly for all commands and options, including edge cases like partial inputs and invalid commands.


## Overview

CLIMaxxing follows these steps to generate and run tests:

1. **Parsing**: The tool reads the bash completion script and parses it to extract all commands, subcommands, and their respective options.

2. **Test Generation**: Using the parsed information, CLIMaxxing generates a series of BATS tests. These include:
   - Full completion tests for each command and subcommand
   - Incremental completion tests, checking partial option lists
   - Tests for invalid inputs
   - Tests for partial command inputs

3. **Mock Creation**: The tool generates a mock version of the CLI tool being tested. This mock intercepts completion requests and returns predefined outputs, allowing for controlled testing.

4. **BATS Test Suite**: All generated tests are written into a BATS test file. This file includes setup and teardown functions to manage the testing environment.

5. **Test Execution**: The generated BATS tests can then be run using the BATS framework, providing a detailed report of passing and failing completions.

## Example

Let's say we're testing the completions for a CLI tool called `cast`. Here's how you might use CLIMaxxing:

1. Run the CLIMaxxing generator:
   ```
   cargo run -- cast.d
   ```

2. This generates two files:
   - `test_cast_completion.bats`: The BATS test file
   - `cast_mock`: The mock cast script

3. The generated `test_cast_completion.bats` might include tests like:
   ```bash
   @test "Test completion for 'cast call'" {
       mock_set_output "$CAST_MOCK" "--rpc-url --from --interactive --private-key"
       run cast call --generate-bash-completion
       assert_success
       assert_output --partial "--rpc-url --from --interactive --private-key"
   }

   @test "Test incremental completion for 'cast call' (2 options)" {
       mock_set_output "$CAST_MOCK" "--rpc-url --from"
       run cast call --generate-bash-completion
       assert_success
       assert_output --partial "--rpc-url --from"
   }
   ```

4. Run the BATS tests:
   ```
   bats test_cast_completion.bats
   ```

5. BATS will execute all the tests and provide a report, for example:
   ```
   ✓ Test completion for 'cast call'
   ✓ Test incremental completion for 'cast call' (2 options)
   ✓ Test completion for invalid input
   ✓ Test completion for partial input 'cast to-'
   ```

