#!/bin/bash

# Premium Features Test Runner
# Runs all unit tests for subscription, cashflow forecasting, and scenario planning

set -e

echo "🧪 Running Premium Features Tests..."
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
SCHEME="ClariFi iOS"
DESTINATION='platform=iOS Simulator,name=iPhone 15'

# Function to run a test suite
run_test_suite() {
    local test_class=$1
    local test_name=$2
    
    echo ""
    echo "${YELLOW}Running ${test_name}...${NC}"
    
    if xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"ClariFi_iOSTests/${test_class}" \
        2>&1 | grep -E "(Test Suite|Test Case|passed|failed)"; then
        echo "${GREEN}✓ ${test_name} completed${NC}"
        return 0
    else
        echo "${RED}✗ ${test_name} failed${NC}"
        return 1
    fi
}

# Track overall success
FAILED=0

# Run Subscription Service Tests
run_test_suite "SubscriptionServiceTests" "Subscription Service Tests" || FAILED=1

# Run Cashflow Forecasting Tests
run_test_suite "CashflowForecastingServiceTests" "Cashflow Forecasting Tests" || FAILED=1

# Run Scenario Planning Tests
run_test_suite "ScenarioPlanningServiceTests" "Scenario Planning Tests" || FAILED=1

# Summary
echo ""
echo "=================================="
if [ $FAILED -eq 0 ]; then
    echo "${GREEN}✓ All premium feature tests passed!${NC}"
    exit 0
else
    echo "${RED}✗ Some tests failed${NC}"
    exit 1
fi
