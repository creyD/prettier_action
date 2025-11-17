#!/usr/bin/env bash

# Test helper functions for prettier_action tests

# Set up a temporary test directory
setup_test_repo() {
    export TEST_TEMP_DIR="$(mktemp -d)"
    cd "$TEST_TEMP_DIR" || exit 1
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
}

# Clean up temporary test directory
teardown_test_repo() {
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a sample file for testing
create_sample_file() {
    local filename="${1:-test.js}"
    local content="${2:-const x=1;const y=2;}"
    echo "$content" > "$filename"
}

# Create a sample package.json
create_package_json() {
    cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "description": "Test project"
}
EOF
}

# Mock git environment variables for GitHub Actions
mock_github_env() {
    export GITHUB_ACTOR="${GITHUB_ACTOR:-test-actor}"
    export GITHUB_ACTOR_ID="${GITHUB_ACTOR_ID:-12345}"
    export GITHUB_ACTION_PATH="${GITHUB_ACTION_PATH:-/app}"
    export GITHUB_BASE_REF="${GITHUB_BASE_REF:-main}"
    export GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/null}"
    export INPUT_GITHUB_TOKEN="${INPUT_GITHUB_TOKEN:-test-token}"
}

# Set default input environment variables
set_default_inputs() {
    export INPUT_WORKING_DIRECTORY="${INPUT_WORKING_DIRECTORY:-}"
    export INPUT_PRETTIER_VERSION="${INPUT_PRETTIER_VERSION:-latest}"
    export INPUT_PRETTIER_OPTIONS="${INPUT_PRETTIER_OPTIONS:---write **/*.js}"
    export INPUT_PRETTIER_PLUGINS="${INPUT_PRETTIER_PLUGINS:-}"
    export INPUT_ALLOW_OTHER_PLUGINS="${INPUT_ALLOW_OTHER_PLUGINS:-false}"
    export INPUT_CLEAN_NODE_FOLDER="${INPUT_CLEAN_NODE_FOLDER:-true}"
    export INPUT_ONLY_CHANGED="${INPUT_ONLY_CHANGED:-false}"
    export INPUT_ONLY_CHANGED_PR="${INPUT_ONLY_CHANGED_PR:-false}"
    export INPUT_FILE_PATTERN="${INPUT_FILE_PATTERN:-*}"
    export INPUT_DRY="${INPUT_DRY:-false}"
    export INPUT_NO_COMMIT="${INPUT_NO_COMMIT:-false}"
    export INPUT_SAME_COMMIT="${INPUT_SAME_COMMIT:-false}"
    export INPUT_COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE:-Automated formatting}"
    export INPUT_COMMIT_DESCRIPTION="${INPUT_COMMIT_DESCRIPTION:-}"
    export INPUT_COMMIT_OPTIONS="${INPUT_COMMIT_OPTIONS:-}"
    export INPUT_PUSH_OPTIONS="${INPUT_PUSH_OPTIONS:-}"
    export INPUT_GIT_IDENTITY="${INPUT_GIT_IDENTITY:-actions}"
}

# Load a bash script without executing it (for testing functions)
load_script_functions() {
    local script_path="$1"
    # Source only the function definitions, not the main program
    # We extract functions by finding lines between function definitions and the main program block
    sed -n '/^_git_setup/,/^}/p' "$script_path" > "$TEST_TEMP_DIR/functions.sh"
    sed -n '/^_git_changed/,/^}/p' "$script_path" >> "$TEST_TEMP_DIR/functions.sh"
    source "$TEST_TEMP_DIR/functions.sh"
}
