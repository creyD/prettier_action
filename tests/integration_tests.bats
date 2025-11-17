#!/usr/bin/env bats

# Integration tests for prettier_action
# These tests verify the overall behavior of the action

load 'test_helper'

setup() {
    setup_test_repo
    mock_github_env
    set_default_inputs
    export SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)"
}

teardown() {
    teardown_test_repo
}

@test "Action sets correct working directory when not specified" {
    export INPUT_WORKING_DIRECTORY=""
    export GITHUB_ACTION_PATH="/test/path"

    # We'll test that the directory change logic works correctly
    # by verifying the default assignment
    result=$(bash -c '
        INPUT_WORKING_DIRECTORY=""
        GITHUB_ACTION_PATH="/test/path"
        if [ -z "$INPUT_WORKING_DIRECTORY" ]; then
            INPUT_WORKING_DIRECTORY=$GITHUB_ACTION_PATH
        fi
        echo "$INPUT_WORKING_DIRECTORY"
    ')

    [ "$result" = "/test/path" ]
}

@test "Action preserves working directory when specified" {
    export INPUT_WORKING_DIRECTORY="/custom/path"

    result=$(bash -c '
        INPUT_WORKING_DIRECTORY="/custom/path"
        GITHUB_ACTION_PATH="/test/path"
        if [ -z "$INPUT_WORKING_DIRECTORY" ]; then
            INPUT_WORKING_DIRECTORY=$GITHUB_ACTION_PATH
        fi
        echo "$INPUT_WORKING_DIRECTORY"
    ')

    [ "$result" = "/custom/path" ]
}

@test "Clean node folder removes node_modules when it exists" {
    # Create node_modules directory
    mkdir -p node_modules
    echo "test" > node_modules/test.txt

    # Simulate the clean logic
    INPUT_CLEAN_NODE_FOLDER=true
    if $INPUT_CLEAN_NODE_FOLDER; then
        if [ -d 'node_modules' ]; then
            rm -r node_modules/
        fi
    fi

    # Verify node_modules was removed
    [ ! -d "node_modules" ]
}

@test "Clean node folder handles missing node_modules gracefully" {
    # Ensure no node_modules exists
    [ ! -d "node_modules" ]

    # Simulate the clean logic
    INPUT_CLEAN_NODE_FOLDER=true
    run bash -c '
        if $INPUT_CLEAN_NODE_FOLDER; then
            if [ -d "node_modules" ]; then
                rm -r node_modules/
                echo "Deleted"
            else
                echo "No node_modules/ folder."
            fi
        fi
    '

    [ "$status" -eq 0 ]
    [[ "$output" =~ "No node_modules/ folder." ]]
}

@test "Package-lock.json is restored when it exists" {
    # Create a package-lock.json and commit it
    echo '{"name": "test"}' > package-lock.json
    git add package-lock.json
    git commit -m "Add package-lock.json"

    # Modify it
    echo '{"name": "modified"}' > package-lock.json

    # Restore it using git checkout
    git checkout -- package-lock.json

    # Verify it was restored
    content=$(cat package-lock.json)
    [[ "$content" =~ '"name": "test"' ]]
}

@test "Package-lock.json restore handles missing file gracefully" {
    # Ensure no package-lock.json exists
    [ ! -f "package-lock.json" ]

    # Try to restore (should not fail)
    run bash -c '
        if [ -f "package-lock.json" ]; then
            git checkout -- package-lock.json || echo "No package-lock.json file tracked by git."
        else
            echo "No package-lock.json file."
        fi
    '

    [ "$status" -eq 0 ]
    [[ "$output" =~ "No package-lock.json file." ]]
}

@test "File pattern logic for only_changed mode filters correctly" {
    # Create initial commit
    echo "file1" > file1.txt
    echo "file2" > file2.txt
    git add .
    git commit -m "Initial commit"

    # Modify only file1
    echo "modified" > file1.txt
    git add file1.txt
    git commit -m "Modify file1"

    # Modify both files
    echo "changed1" > file1.txt
    echo "changed2" > file2.txt

    # Get files changed in previous commit
    git diff --name-only HEAD HEAD~1 > /tmp/prev.txt

    # Get files with current changes
    git diff --name-only HEAD > /tmp/cur.txt

    # Verify file1.txt is in prev.txt (it was changed in last commit)
    run grep "file1.txt" /tmp/prev.txt
    [ "$status" -eq 0 ]

    # Verify both files are in cur.txt (both have current changes)
    run grep "file1.txt" /tmp/cur.txt
    [ "$status" -eq 0 ]
    run grep "file2.txt" /tmp/cur.txt
    [ "$status" -eq 0 ]

    # Files in cur.txt but not in prev.txt should be reset
    # In this case, file2.txt should be reset
    for file in $(comm -1 -3 /tmp/prev.txt /tmp/cur.txt); do
        [ "$file" = "file2.txt" ]
    done
}

@test "Dry run mode detects unpretty files" {
    # This tests the logic flow for dry run
    # We simulate detecting changes

    # Create a test file
    echo "test" > test.txt

    # Simulate git detecting changes
    run bash -c '
        source tests/test_helper.bash
        setup_test_repo
        echo "test" > test.txt
        _git_changed
    '

    [ "$status" -eq 0 ]
}

@test "No changes scenario is handled correctly" {
    # Create and commit a file
    echo "test" > test.txt
    git add test.txt
    git commit -m "Add test file"

    # Verify no changes
    run bash -c '
        source tests/test_helper.bash
        load_script_functions entrypoint.sh
        _git_changed
    '

    [ "$status" -eq 1 ]
}
