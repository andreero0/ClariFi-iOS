#!/bin/bash

# Comprehensive script to fix Xcode test target membership issues
# This addresses the "No such module XCTest" and @testable import warnings

set -e

echo "🔧 Fixing Xcode Test Target Membership Issues"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Current Issues:${NC}"
echo -e "${RED}❌ 'No such module XCTest' errors${NC}"
echo -e "${RED}❌ '@testable import' warnings${NC}"
echo -e "${RED}❌ Test files compiled as part of main app target${NC}"

echo -e "\n${BLUE}🔍 Test Files That Need Fixing:${NC}"
TEST_FILES=(
    "ClariFi iOSTests/Integration/EndToEndFlowTests.swift"
    "ClariFi iOSTests/Concurrency/MainActorIsolationTests.swift"
    "ClariFi iOSTests/Performance/PerformanceBenchmarks.swift"
    "ClariFi iOSTests/DependencyInjection/DIContainerTests.swift"
    "ClariFi iOSTests/Services/LLMCacheThreadSafetyTests.swift"
    "ClariFi iOSTests/Models/CurrencyFormatterTests.swift"
    "ClariFi iOSTests/Services/ParserConcurrencyTests.swift"
    "ClariFi iOSTests/Services/AnalyticsTests.swift"
    "ClariFi iOSTests/Repositories/RepositoryThreadSafetyTests.swift"
)

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        echo -e "${GREEN}✅ $test_file${NC}"
    else
        echo -e "${RED}❌ $test_file${NC}"
    fi
done

echo -e "\n${BLUE}🛠️  SOLUTION: Fix Target Membership in Xcode${NC}"
echo -e "${YELLOW}Follow these steps to fix the target membership:${NC}"

echo -e "\n${BLUE}📝 Method 1: Remove and Re-add Test Files (Recommended)${NC}"
echo -e "${YELLOW}1. Open Xcode project${NC}"
echo -e "${YELLOW}2. In Project Navigator, select ALL test files listed above${NC}"
echo -e "${YELLOW}3. Press Delete key and choose 'Remove Reference' (NOT 'Move to Trash')${NC}"
echo -e "${YELLOW}4. Right-click on 'ClariFi iOSTests' group in Project Navigator${NC}"
echo -e "${YELLOW}5. Select 'Add Files to \"ClariFi iOS\"'${NC}"
echo -e "${YELLOW}6. Navigate to the test files and select them${NC}"
echo -e "${YELLOW}7. In the dialog, ensure ONLY 'ClariFi iOSTests' target is checked${NC}"
echo -e "${YELLOW}8. Click 'Add'${NC}"

echo -e "\n${BLUE}📝 Method 2: Fix Target Membership for Existing Files${NC}"
echo -e "${YELLOW}For each test file:${NC}"
echo -e "${YELLOW}1. Select the file in Project Navigator${NC}"
echo -e "${YELLOW}2. Open File Inspector (right panel, first tab)${NC}"
echo -e "${YELLOW}3. Scroll down to 'Target Membership' section${NC}"
echo -e "${YELLOW}4. UNCHECK 'ClariFi_iOS' (main app target)${NC}"
echo -e "${YELLOW}5. ENSURE 'ClariFi iOSTests' is CHECKED${NC}"
echo -e "${YELLOW}6. If 'ClariFi iOSTests' is not listed, add it first${NC}"

echo -e "\n${BLUE}✅ Verification Steps:${NC}"
echo -e "${YELLOW}After fixing target membership:${NC}"
echo -e "${YELLOW}1. Clean Build Folder (Product > Clean Build Folder)${NC}"
echo -e "${YELLOW}2. Build project (Product > Build)${NC}"
echo -e "${YELLOW}3. Check that 'No such module XCTest' errors are gone${NC}"
echo -e "${YELLOW}4. Run tests (Product > Test or Cmd+U)${NC}"
echo -e "${YELLOW}5. Verify all tests pass${NC}"

echo -e "\n${BLUE}🚨 Common Issues & Solutions:${NC}"
echo -e "${RED}• If files are still in wrong target:${NC}"
echo -e "   - Use Method 1 (remove and re-add) for cleanest fix"
echo -e "   - Check File Inspector for each file"
echo -e "${RED}• If tests don't run:${NC}"
echo -e "   - Check test target scheme (Product > Scheme > Edit Scheme)"
echo -e "   - Verify test files are in correct group"
echo -e "${RED}• If build errors persist:${NC}"
echo -e "   - Clean derived data (Xcode > Preferences > Locations > Derived Data)"
echo -e "   - Restart Xcode"
echo -e "   - Check that test files have correct file extensions (.swift)"

echo -e "\n${BLUE}💡 Pro Tips:${NC}"
echo -e "${YELLOW}• You can select multiple files at once in Project Navigator${NC}"
echo -e "${YELLOW}• Use Cmd+Click to select non-contiguous files${NC}"
echo -e "${YELLOW}• The 'Add Files' dialog allows you to add multiple files at once${NC}"
echo -e "${YELLOW}• Always clean build folder after making target changes${NC}"

echo -e "\n${GREEN}✅ Instructions provided. Follow the steps above to fix target membership.${NC}"
echo -e "${BLUE}🎯 This will resolve all XCTest module errors and @testable import warnings.${NC}"
