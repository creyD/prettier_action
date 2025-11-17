#!/usr/bin/env bash

# Test runner script for prettier_action
# This script installs BATS and runs all tests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BATS_VERSION="v1.11.0"
BATS_INSTALL_DIR="$SCRIPT_DIR/bats"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Prettier Action Test Runner"
echo "========================================="
echo ""

# Function to install BATS
install_bats() {
    echo -e "${YELLOW}Installing BATS (Bash Automated Testing System)...${NC}"

    if [ -d "$BATS_INSTALL_DIR" ]; then
        echo "BATS already installed at $BATS_INSTALL_DIR"
        return 0
    fi

    # Clone BATS
    git clone --depth 1 --branch "$BATS_VERSION" https://github.com/bats-core/bats-core.git "$BATS_INSTALL_DIR"

    # Clone support libraries
    mkdir -p "$BATS_INSTALL_DIR/test_helper"
    git clone --depth 1 https://github.com/bats-core/bats-support.git "$BATS_INSTALL_DIR/test_helper/bats-support"
    git clone --depth 1 https://github.com/bats-core/bats-assert.git "$BATS_INSTALL_DIR/test_helper/bats-assert"

    echo -e "${GREEN}BATS installed successfully!${NC}"
    echo ""
}

# Function to check if BATS is available
check_bats() {
    if [ -x "$BATS_INSTALL_DIR/bin/bats" ]; then
        return 0
    fi
    return 1
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    # Check if BATS is installed, if not install it
    if ! check_bats; then
        install_bats
    fi

    echo -e "${YELLOW}Running tests...${NC}"
    echo ""

    # Run all test files
    TEST_FILES=(
        "$SCRIPT_DIR/unit_tests.bats"
        "$SCRIPT_DIR/plugin_validation_tests.bats"
        "$SCRIPT_DIR/integration_tests.bats"
    )

    FAILED=0

    for test_file in "${TEST_FILES[@]}"; do
        if [ -f "$test_file" ]; then
            echo "Running $(basename "$test_file")..."
            if "$BATS_INSTALL_DIR/bin/bats" "$test_file"; then
                echo -e "${GREEN}✓ $(basename "$test_file") passed${NC}"
            else
                echo -e "${RED}✗ $(basename "$test_file") failed${NC}"
                FAILED=1
            fi
            echo ""
        fi
    done

    echo "========================================="
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    --install-only)
        install_bats
        exit 0
        ;;
    --help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --install-only    Only install BATS without running tests"
        echo "  --help            Show this help message"
        echo ""
        exit 0
        ;;
    *)
        main
        ;;
esac
