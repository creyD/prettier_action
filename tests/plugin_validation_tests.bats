#!/usr/bin/env bats

# Integration tests for prettier plugin validation

load 'test_helper'

setup() {
    setup_test_repo
    mock_github_env
    set_default_inputs
}

teardown() {
    teardown_test_repo
}

# Test valid prettier plugin patterns
@test "Valid @prettier/plugin-* format should pass validation" {
    # Test the regex pattern used in entrypoint.sh
    plugin="@prettier/plugin-php"

    run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"

    [ "$status" -eq 0 ]
}

@test "Valid prettier-plugin-* format should pass validation" {
    plugin="prettier-plugin-java"

    run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"

    [ "$status" -eq 0 ]
}

@test "Valid @scope/prettier-plugin-* format should pass validation" {
    plugin="@company/prettier-plugin-custom"

    run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"

    [ "$status" -eq 0 ]
}

@test "Invalid plugin name should fail validation" {
    plugin="some-random-package"

    run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"

    [ "$status" -eq 1 ]
}

@test "Invalid plugin with wrong prefix should fail validation" {
    plugin="@other/plugin-something"

    run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"

    [ "$status" -eq 1 ]
}

@test "Multiple valid plugins should all pass validation" {
    plugins="@prettier/plugin-php prettier-plugin-java @scope/prettier-plugin-custom"

    for plugin in $plugins; do
        run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"
        [ "$status" -eq 0 ]
    done
}

@test "Plugin name with uppercase should fail validation" {
    plugin="@prettier/plugin-PHP"

    run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"

    [ "$status" -eq 1 ]
}

@test "Plugin name with numbers or underscores should fail validation" {
    plugin1="@prettier/plugin-test123"
    plugin2="prettier-plugin-test_name"

    run bash -c "echo '$plugin1' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"
    [ "$status" -eq 1 ]

    run bash -c "echo '$plugin2' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"
    [ "$status" -eq 1 ]
}

@test "Official prettier plugins should be recognized" {
    # List of known official prettier plugins
    plugins=(
        "@prettier/plugin-php"
        "@prettier/plugin-ruby"
        "@prettier/plugin-xml"
    )

    for plugin in "${plugins[@]}"; do
        run bash -c "echo '$plugin' | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'"
        [ "$status" -eq 0 ]
    done
}
