import re
import json

def parse_completion_script(script_content):
    commands = {}
    current_command = None
    
    for line in script_content.split('\n'):
        if line.strip().startswith('cast)'):
            current_command = 'cast'
            commands[current_command] = {'subcommands': [], 'options': []}
        elif line.strip().startswith('cast__'):
            current_command = line.split(')')[0].replace('__', ' ')
            commands[current_command] = {'options': []}
        elif 'opts=' in line and current_command:
            options = re.findall(r'(-\w|--\w+)', line)
            commands[current_command]['options'].extend(options)
        elif current_command == 'cast' and '" -- "${cur}"' in line:
            subcommands = re.findall(r'\w+', line)
            commands[current_command]['subcommands'].extend(subcommands)

    return commands

def generate_tests(commands):
    tests = []

    # Test basic cast command completion
    tests.append("""
def test_cast_basic_completion(bash_completion):
    result = bash_completion('cast ')
    assert 'max-int' in result
    assert 'access-list' in result
    assert '--help' in result
""")

    # Test subcommand completion
    for command, data in commands.items():
        if command == 'cast' and 'subcommands' in data:
            for subcommand in data['subcommands']:
                tests.append(f"""
def test_cast_{subcommand}_completion(bash_completion):
    result = bash_completion('cast {subcommand[0]} ')
    assert '{subcommand}' in result
""")

        # Test option completion
        if 'options' in data:
            cmd = command.replace(' ', '_')
            tests.append(f"""
def test_{cmd}_option_completion(bash_completion):
    result = bash_completion('cast {command} -')
    assert '{data['options'][0]}' in result
""")

    # Test partial input completion
    tests.append("""
def test_partial_input_completion(bash_completion):
    result = bash_completion('cast to-d')
    assert 'to-dec' in result
""")

    # Test invalid input completion
    tests.append("""
def test_invalid_input_completion(bash_completion):
    result = bash_completion('cast invalid-command')
    assert result == []
""")

    return tests

def main(script_file):
    with open(script_file, 'r') as f:
        script_content = f.read()

    commands = parse_completion_script(script_content)
    tests = generate_tests(commands)

    with open('test_cast_completion.py', 'w') as f:
        f.write("""import pytest

@pytest.fixture
def bash_completion(bash_process):
    def complete(text):
        bash_process.sendline(f'cast {text}\\t\\t')
        bash_process.expect_exact(f'cast {text}')
        return bash_process.before.decode().split()
    return complete

""")
        f.write('\n'.join(tests))

    print("Test file 'test_cast_completion.py' has been generated.")

if __name__ == "__main__":
    main("cast.d")  # Replace with the actual filename of the Bash completion script
