#!/bin/bash

# Final Integration Tests Runner
# Tests complete user journeys and all critical functionality

echo "=========================================="
echo "Running Final Integration Tests"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Run the tests
echo "Running comprehensive integration tests..."
echo ""

xcodebuild test \
    -scheme ClariFi_iOS \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:ClariFi_iOSTests/FinalIntegrationTests \
    2>&1 | tee final_integration_test_results.log

# Check if tests passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo "✓ All Final Integration Tests PASSED"
    echo -e "==========================================${NC}"
    echo ""
    echo "Test Coverage:"
    echo "  ✓ Complete user journey (install to first transaction)"
    echo "  ✓ All 18 budget templates with transactions"
    echo "  ✓ LLM categorization with real statements"
    echo "  ✓ Error scenario handling"
    echo "  ✓ Data consistency across contexts"
    echo "  ✓ Performance with large datasets"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}=========================================="
    echo "✗ Some Final Integration Tests FAILED"
    echo -e "==========================================${NC}"
    echo ""
    echo "Check final_integration_test_results.log for details"
    echo ""
    exit 1
fi
