#!/usr/bin/env bats

# Unit tests for prettier_action entrypoint.sh functions

load 'test_helper'

setup() {
    setup_test_repo
    mock_github_env
    set_default_inputs

    # Load the functions from entrypoint.sh
    export SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_DIRNAME}")" && pwd)"
    load_script_functions "$SCRIPT_DIR/entrypoint.sh"
}

teardown() {
    teardown_test_repo
}

# Test _git_setup function with 'actions' identity
@test "_git_setup creates .netrc file with correct permissions" {
    export INPUT_GIT_IDENTITY="actions"

    run _git_setup

    [ "$status" -eq 0 ]
    [ -f "$HOME/.netrc" ]

    # Check file permissions (should be 600)
    local perms=$(stat -c "%a" "$HOME/.netrc")
    [ "$perms" = "600" ]
}

@test "_git_setup configures git with 'actions' identity" {
    export INPUT_GIT_IDENTITY="actions"

    run _git_setup

    [ "$status" -eq 0 ]

    # Check git config
    local git_name=$(git config --global user.name)
    local git_email=$(git config --global user.email)

    [ "$git_name" = "GitHub Action" ]
    [ "$git_email" = "actions@github.com" ]
}

@test "_git_setup configures git with 'author' identity" {
    export INPUT_GIT_IDENTITY="author"
    export GITHUB_ACTOR="test-user"
    export GITHUB_ACTOR_ID="54321"

    run _git_setup

    [ "$status" -eq 0 ]

    # Check git config
    local git_name=$(git config --global user.name)
    local git_email=$(git config --global user.email)

    [ "$git_name" = "test-user" ]
    [ "$git_email" = "54321+test-user@users.noreply.github.com" ]
}

@test "_git_setup fails with invalid identity" {
    export INPUT_GIT_IDENTITY="invalid"

    run _git_setup

    [ "$status" -eq 1 ]
    [[ "$output" =~ "GIT_IDENTITY must be either 'author' or 'actions'" ]]
}

@test "_git_changed returns true when files are modified" {
    # Create and commit a file
    echo "test" > test.txt
    git add test.txt
    git commit -m "Initial commit"

    # Modify the file
    echo "modified" > test.txt

    run _git_changed

    [ "$status" -eq 0 ]
}

@test "_git_changed returns false when no files are modified" {
    # Create and commit a file
    echo "test" > test.txt
    git add test.txt
    git commit -m "Initial commit"

    # No modifications
    run _git_changed

    [ "$status" -eq 1 ]
}

@test "_git_changed returns true for untracked files" {
    # Create a file without committing
    echo "test" > untracked.txt

    run _git_changed

    [ "$status" -eq 0 ]
}

@test "_git_changed returns true for staged files" {
    # Create and commit a file
    echo "test" > test.txt
    git add test.txt
    git commit -m "Initial commit"

    # Add a new file and stage it
    echo "new file" > new.txt
    git add new.txt

    run _git_changed

    [ "$status" -eq 0 ]
}
