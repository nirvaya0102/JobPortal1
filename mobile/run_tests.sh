#!/bin/bash

# Flutter Mobile App Test Runner Script
# This script helps run tests easily with various options

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to display usage
show_usage() {
    echo "Flutter Mobile App Test Runner"
    echo ""
    echo "Usage: ./run_tests.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  all             Run all tests"
    echo "  models          Run model tests only"
    echo "  widgets         Run widget tests only"
    echo "  storage         Run storage tests only"
    echo "  coverage        Run tests with coverage report"
    echo "  watch           Run tests in watch mode"
    echo "  verbose         Run tests with verbose output"
    echo "  help            Show this help message"
    echo ""
}

# Function to run all tests
run_all_tests() {
    print_info "Running all tests..."
    flutter test --verbose
}

# Function to run model tests
run_model_tests() {
    print_info "Running model tests..."
    flutter test test/features/jobs/models/ \
               test/features/notifications/models/ \
               --verbose
}

# Function to run widget tests
run_widget_tests() {
    print_info "Running widget tests..."
    flutter test test/shared/widgets/ --verbose
}

# Function to run storage tests
run_storage_tests() {
    print_info "Running storage tests..."
    flutter test test/core/storage/ --verbose
}

# Function to run tests with coverage
run_coverage() {
    print_info "Running tests with coverage..."
    flutter test --coverage
    print_info "Coverage report generated at coverage/lcov.info"
    
    # Check if lcov is installed
    if command -v genhtml &> /dev/null; then
        print_info "Generating HTML coverage report..."
        genhtml coverage/lcov.info -o coverage/html
        print_info "HTML report generated at coverage/html/index.html"
        
        # Try to open in browser (macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        fi
    else
        print_warn "lcov not installed. Install to generate HTML reports:"
        echo "  macOS: brew install lcov"
        echo "  Linux: sudo apt-get install lcov"
    fi
}

# Function to run tests in watch mode
run_watch_mode() {
    print_info "Running tests in watch mode..."
    print_warn "Press Ctrl+C to exit"
    flutter test --watch
}

# Function to run tests with verbose output
run_verbose() {
    print_info "Running all tests with verbose output..."
    flutter test --verbose
}

# Main script logic
case "${1:-help}" in
    all)
        run_all_tests
        ;;
    models)
        run_model_tests
        ;;
    widgets)
        run_widget_tests
        ;;
    storage)
        run_storage_tests
        ;;
    coverage)
        run_coverage
        ;;
    watch)
        run_watch_mode
        ;;
    verbose)
        run_verbose
        ;;
    help)
        show_usage
        ;;
    *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac

print_info "Test execution completed!"
