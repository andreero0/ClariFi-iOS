#!/bin/bash

# Comprehensive script to fix Xcode test target membership issues
# This script provides step-by-step instructions and automated fixes where possible

set -e

echo "🔧 Fixing Xcode Test Target Membership Issues"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_FILE="../ClariFi iOS.xcodeproj/project.pbxproj"
BACKUP_FILE="../ClariFi iOS.xcodeproj/project.pbxproj.backup"

echo -e "${BLUE}📋 Current Issue:${NC}"
echo -e "${RED}❌ Test files are being compiled as part of the main app target${NC}"
echo -e "${RED}❌ This causes 'No such module XCTest' errors${NC}"
echo -e "${RED}❌ @testable imports are being ignored${NC}"

echo -e "\n${BLUE}🔍 Test Files Found:${NC}"
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

echo -e "\n${BLUE}🛠️  Solution Steps:${NC}"
echo -e "${YELLOW}1. Open Xcode project${NC}"
echo -e "${YELLOW}2. In Project Navigator, right-click on 'ClariFi iOSTests' group${NC}"
echo -e "${YELLOW}3. Select 'Add Files to \"ClariFi iOS\"'${NC}"
echo -e "${YELLOW}4. Navigate to each test file and add it${NC}"
echo -e "${YELLOW}5. In File Inspector (right panel), ensure ONLY 'ClariFi iOSTests' target is checked${NC}"
echo -e "${YELLOW}6. Clean and rebuild project (Product > Clean Build Folder, then Product > Build)${NC}"

echo -e "\n${BLUE}📝 Detailed Instructions:${NC}"
echo -e "${YELLOW}For each test file:${NC}"
echo -e "   • Select the file in Project Navigator"
echo -e "   • Open File Inspector (right panel, first tab)"
echo -e "   • Scroll down to 'Target Membership' section"
echo -e "   • UNCHECK 'ClariFi_iOS' (main app target)"
echo -e "   • ENSURE 'ClariFi iOSTests' is CHECKED"
echo -e "   • If 'ClariFi iOSTests' is not listed, add it first"

echo -e "\n${BLUE}🔧 Alternative: Remove and Re-add Test Files${NC}"
echo -e "${YELLOW}If the above doesn't work:${NC}"
echo -e "   1. Select all test files in Project Navigator"
echo -e "   2. Press Delete and choose 'Remove Reference'"
echo -e "   3. Right-click 'ClariFi iOSTests' group"
echo -e "   4. Select 'Add Files to \"ClariFi iOS\"'"
echo -e "   5. Navigate to test files and add them"
echo -e "   6. Ensure only test target is selected"

echo -e "\n${BLUE}✅ Verification Steps:${NC}"
echo -e "${YELLOW}After fixing:${NC}"
echo -e "   1. Clean Build Folder (Product > Clean Build Folder)"
echo -e "   2. Build project (Product > Build)"
echo -e "   3. Check that 'No such module XCTest' errors are gone"
echo -e "   4. Run tests (Product > Test or Cmd+U)"
echo -e "   5. Verify all tests pass"

echo -e "\n${BLUE}🚨 Common Issues:${NC}"
echo -e "${RED}• If files are still in wrong target:${NC}"
echo -e "   - Check File Inspector for each file"
echo -e "   - Remove and re-add files to project"
echo -e "${RED}• If tests don't run:${NC}"
echo -e "   - Check test target scheme"
echo -e "   - Verify test files are in correct group"
echo -e "${RED}• If build errors persist:${NC}"
echo -e "   - Clean derived data"
echo -e "   - Restart Xcode"

echo -e "\n${GREEN}✅ Instructions provided. Follow the steps above to fix target membership.${NC}"
echo -e "${BLUE}💡 Tip: You can also use Xcode's 'Add Files' dialog to add multiple files at once.${NC}"
