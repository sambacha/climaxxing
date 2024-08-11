use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader, Write};
use std::path::Path;
use regex::Regex;

#[derive(Debug, Clone)]
struct Command {
    subcommands: Vec<String>,
    options: Vec<String>,
}

fn parse_completion_script(script_path: &Path) -> HashMap<String, Command> {
    let file = File::open(script_path).expect("Failed to open script file");
    let reader = BufReader::new(file);
    let mut commands = HashMap::new();
    let mut current_command = None;

    for line in reader.lines() {
        let line = line.expect("Failed to read line");
        if line.trim().starts_with("cast)") {
            current_command = Some("cast".to_string());
            commands.insert(current_command.clone().unwrap(), Command { subcommands: Vec::new(), options: Vec::new() });
        } else if line.trim().starts_with("cast__") {
            current_command = Some(line.split(')').next().unwrap().replace("__", " "));
            commands.insert(current_command.clone().unwrap(), Command { subcommands: Vec::new(), options: Vec::new() });
        } else if line.contains("opts=") && current_command.is_some() {
            let options: Vec<String> = Regex::new(r"(-\w|--\w+)")
                .unwrap()
                .find_iter(&line)
                .map(|m| m.as_str().to_string())
                .collect();
            commands.get_mut(&current_command.clone().unwrap()).unwrap().options.extend(options);
        } else if current_command == Some("cast".to_string()) && line.contains("\" -- \"${cur}\"") {
            let subcommands: Vec<String> = Regex::new(r"\w+")
                .unwrap()
                .find_iter(&line)
                .map(|m| m.as_str().to_string())
                .collect();
            commands.get_mut("cast").unwrap().subcommands.extend(subcommands);
        }
    }

    commands
}

fn generate_bats_tests(commands: &HashMap<String, Command>) -> String {
    let mut tests = String::new();

    tests.push_str(r#"#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-mock/src/bats-mock'

setup() {
    export CAST_MOCK="${BATS_TEST_DIRNAME}/cast_mock"
    export PATH="${BATS_TEST_DIRNAME}:$PATH"
}

teardown() {
    rm -f "$CAST_MOCK"
}

"#);

    for (command, data) in commands {
        let options = data.options.join(" ");
        
        tests.push_str(&format!(r#"
@test "Test completion for 'cast {}'" {{
    mock_set_output "$CAST_MOCK" "{}"
    run cast {} --generate-bash-completion
    assert_success
    assert_output --partial "{}"
}}
"#, command, options, command, options));

        // Generate incremental stubbing tests
        for i in 1..=data.options.len() {
            let partial_options = data.options[0..i].join(" ");
            tests.push_str(&format!(r#"
@test "Test incremental completion for 'cast {}' ({} options)" {{
    mock_set_output "$CAST_MOCK" "{}"
    run cast {} --generate-bash-completion
    assert_success
    assert_output --partial "{}"
}}
"#, command, i, partial_options, command, partial_options));
        }
    }

    // Add test for invalid input
    tests.push_str(r#"
@test "Test completion for invalid input" {
    run cast invalid-command --generate-bash-completion
    assert_failure
    assert_output --partial "invalid-command: command not found"
}
"#);

    // Add test for partial input
    tests.push_str(r#"
@test "Test completion for partial input 'cast to-'" {
    mock_set_output "$CAST_MOCK" "to-hex to-wei to-unit"
    run cast to- --generate-bash-completion
    assert_success
    assert_output --partial "to-hex to-wei to-unit"
}
"#);

    tests
}

fn main() {
    let script_path = Path::new("cast.d");
    let commands = parse_completion_script(script_path);
    let bats_tests = generate_bats_tests(&commands);

    let mut test_file = File::create("test_cast_completion.bats").expect("Failed to create BATS test file");
    test_file.write_all(bats_tests.as_bytes()).expect("Failed to write to BATS test file");

    println!("BATS test file 'test_cast_completion.bats' has been generated.");

    // Generate the mock cast script
    let mock_script = r#"#!/usr/bin/env bash

if [[ "$*" == *"--generate-bash-completion"* ]]; then
    cat "$CAST_MOCK"
else
    echo "cast $*"
fi
"#;

    let mut mock_file = File::create("cast_mock").expect("Failed to create mock cast script");
    mock_file.write_all(mock_script.as_bytes()).expect("Failed to write to mock cast script");
    std::fs::set_permissions("cast_mock", std::os::unix::fs::PermissionsExt::from_mode(0o755)).expect("Failed to set permissions on mock cast script");

    println!("Mock cast script 'cast_mock' has been generated.");
}
