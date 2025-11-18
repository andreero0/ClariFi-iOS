#!/bin/bash

# Verification script for Task 7.7 Performance Testing and Optimization

echo "🔍 Verifying Task 7.7 Implementation"
echo "====================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        ((FAIL++))
    fi
}

check_content() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $1 contains '$2'"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $1 missing '$2'"
        ((FAIL++))
    fi
}

echo "Checking Test Files..."
check_file "Tests/IntegrationTests/PerformanceTests.swift"
check_content "Tests/IntegrationTests/PerformanceTests.swift" "testAppLaunchTime"
check_content "Tests/IntegrationTests/PerformanceTests.swift" "testOnboardingStepTransitionTime"
check_content "Tests/IntegrationTests/PerformanceTests.swift" "testLLMQueryTime"
check_content "Tests/IntegrationTests/PerformanceTests.swift" "testCategoryLookupTime"
echo ""

echo "Checking Documentation..."
check_file ".kiro/specs/critical-ux-fixes/PERFORMANCE_OPTIMIZATION_GUIDE.md"
check_file ".kiro/specs/critical-ux-fixes/PERFORMANCE_TESTING_QUICK_REFERENCE.md"
check_file ".kiro/specs/critical-ux-fixes/TASK_7.7_PERFORMANCE_TESTING_SUMMARY.md"
check_file ".kiro/specs/critical-ux-fixes/TASK_7.7_COMPLETION_REPORT.md"
echo ""

echo "Checking Scripts..."
check_file "run_performance_tests.sh"
check_file "verify_performance_implementation.sh"
echo ""

echo "Checking Monitoring Infrastructure..."
check_file "Utilities/PerformanceMonitor.swift"
check_file "Utilities/LLMPerformanceMonitor.swift"
check_content "Utilities/PerformanceMonitor.swift" "measure"
check_content "Utilities/LLMPerformanceMonitor.swift" "startQuery"
echo ""

echo "Checking Optimized Services..."
check_file "Services/CategoryMappingService.swift"
check_content "Services/CategoryMappingService.swift" "canonicalNameLookup"
check_content "Services/CategoryMappingService.swift" "aliasLookup"
echo ""

echo "Checking Test Coverage..."
echo "Expected test methods:"
TESTS=(
    "testAppLaunchTime"
    "testDependencyRegistrationTime"
    "testOnboardingStepTransitionTime"
    "testOnboardingValidationTime"
    "testCompleteOnboardingFlowTime"
    "testLLMQueryTime"
    "testLLMFallbackTime"
    "testLLMMerchantNormalizationTime"
    "testBulkLLMCategorizationTime"
    "testCategoryLookupTime"
    "testGetAllCategoriesTime"
    "testCategoryDisplayNameLookupTime"
    "testBulkCategoryLookupTime"
    "testCategoryMappingWithAliases"
    "testMemoryUsageDuringOnboarding"
    "testMemoryUsageWithManyCategories"
    "testCategoryLookupOptimization"
    "testLLMResponseCaching"
    "testNoPerformanceRegression"
)

for test in "${TESTS[@]}"; do
    check_content "Tests/IntegrationTests/PerformanceTests.swift" "$test"
done
echo ""

echo "====================================="
echo "Verification Results:"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Task 7.7 is complete. You can now:"
    echo "  1. Run performance tests: ./run_performance_tests.sh"
    echo "  2. Review optimization guide: .kiro/specs/critical-ux-fixes/PERFORMANCE_OPTIMIZATION_GUIDE.md"
    echo "  3. Check quick reference: .kiro/specs/critical-ux-fixes/PERFORMANCE_TESTING_QUICK_REFERENCE.md"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo "Please review the missing files or content above."
    exit 1
fi

