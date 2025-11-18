#!/bin/bash

# Script to run Navigation UI Tests for ClariFi iOS
# This script runs the comprehensive UI tests for main navigation, dashboard, and transaction list

set -e

echo "🧪 Running Navigation UI Tests for ClariFi iOS"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="ClariFi iOS"
SCHEME="ClariFi iOS"
DESTINATION="platform=iOS Simulator,name=iPhone 16,arch=arm64"
TEST_TARGET="ClariFi_iOSTests/NavigationUITests"

# Check if project exists
if [ ! -d "../${PROJECT_NAME}.xcodeproj" ]; then
    echo -e "${RED}❌ Error: Project not found at ../${PROJECT_NAME}.xcodeproj${NC}"
    echo "Please run this script from the project directory"
    exit 1
fi

echo -e "${BLUE}📱 Test Configuration:${NC}"
echo "   Project: ${PROJECT_NAME}"
echo "   Scheme: ${SCHEME}"
echo "   Destination: ${DESTINATION}"
echo "   Test Target: ${TEST_TARGET}"
echo ""

# Function to run specific test category
run_test_category() {
    local category=$1
    local test_name=$2
    
    echo -e "${BLUE}Running ${category} tests...${NC}"
    
    if xcodebuild test \
        -project "../${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}" \
        -only-testing:"${TEST_TARGET}/${test_name}" \
        2>&1 | grep -E "Test Suite|Test Case|passed|failed"; then
        echo -e "${GREEN}✅ ${category} tests completed${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ ${category} tests failed${NC}"
        echo ""
        return 1
    fi
}

# Main test execution
echo -e "${BLUE}🚀 Starting test execution...${NC}"
echo ""

# Option to run all tests or specific categories
if [ "$1" == "all" ] || [ -z "$1" ]; then
    echo -e "${BLUE}Running all Navigation UI tests...${NC}"
    echo ""
    
    xcodebuild test \
        -project "../${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -destination "${DESTINATION}" \
        -only-testing:"${TEST_TARGET}" \
        | tee test_output.log
    
    # Check results
    if grep -q "Test Suite.*passed" test_output.log; then
        echo ""
        echo -e "${GREEN}✅ All tests passed!${NC}"
        rm test_output.log
        exit 0
    else
        echo ""
        echo -e "${RED}❌ Some tests failed. Check output above.${NC}"
        rm test_output.log
        exit 1
    fi

elif [ "$1" == "tab" ]; then
    echo -e "${BLUE}Running Tab Navigation tests...${NC}"
    run_test_category "Tab Navigation" "testTabViewHasAllRequiredTabs"
    run_test_category "Tab Navigation" "testAppStateInitializesWithDefaultValues"
    run_test_category "Tab Navigation" "testAppStateRefreshTriggersUpdate"
    run_test_category "Tab Navigation" "testAppStateShowingStatementUploadToggle"
    run_test_category "Tab Navigation" "testAppStateShowingTransactionEntryToggle"

elif [ "$1" == "dashboard" ]; then
    echo -e "${BLUE}Running Dashboard tests...${NC}"
    run_test_category "Dashboard" "testDashboardCalculatesCurrentMonthSpending"
    run_test_category "Dashboard" "testDashboardCalculatesCategoryBreakdown"
    run_test_category "Dashboard" "testDashboardCalculatesAverageDailySpending"
    run_test_category "Dashboard" "testDashboardHandlesEmptyTransactions"
    run_test_category "Dashboard" "testDashboardQuickActionsAvailable"

elif [ "$1" == "transactions" ]; then
    echo -e "${BLUE}Running Transaction List tests...${NC}"
    run_test_category "Transaction List" "testTransactionListFetchesAllTransactions"
    run_test_category "Transaction List" "testTransactionListSearchFiltering"
    run_test_category "Transaction List" "testTransactionListCategoryFiltering"
    run_test_category "Transaction List" "testTransactionListDateFiltering"
    run_test_category "Transaction List" "testTransactionListSortByDateDescending"
    run_test_category "Transaction List" "testTransactionListSortByAmountDescending"
    run_test_category "Transaction List" "testTransactionListSortByMerchant"
    run_test_category "Transaction List" "testTransactionListGroupsByDate"
    run_test_category "Transaction List" "testTransactionListExtractsAvailableCategories"

elif [ "$1" == "performance" ]; then
    echo -e "${BLUE}Running Performance tests...${NC}"
    run_test_category "Performance" "testTransactionListPerformanceWithLargeDataset"
    run_test_category "Performance" "testTransactionListGroupingPerformance"

elif [ "$1" == "integration" ]; then
    echo -e "${BLUE}Running Integration tests...${NC}"
    run_test_category "Integration" "testDashboardAndTransactionListShareData"
    run_test_category "Integration" "testAppStateRefreshUpdatesAllViews"

else
    echo -e "${RED}❌ Invalid option: $1${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  all           - Run all navigation UI tests (default)"
    echo "  tab           - Run tab navigation tests only"
    echo "  dashboard     - Run dashboard tests only"
    echo "  transactions  - Run transaction list tests only"
    echo "  performance   - Run performance tests only"
    echo "  integration   - Run integration tests only"
    echo ""
    echo "Examples:"
    echo "  $0              # Run all tests"
    echo "  $0 all          # Run all tests"
    echo "  $0 dashboard    # Run dashboard tests only"
    echo "  $0 performance  # Run performance tests only"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Test execution completed!${NC}"
