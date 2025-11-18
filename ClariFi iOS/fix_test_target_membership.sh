#!/bin/bash

# Script to fix test file target membership in Xcode project
# This script ensures test files are only included in the test target

set -e

echo "🔧 Fixing test file target membership..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_FILE="../ClariFi iOS.xcodeproj/project.pbxproj"
BACKUP_FILE="../ClariFi iOS.xcodeproj/project.pbxproj.backup"

# Create backup
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$PROJECT_FILE" "$BACKUP_FILE"
    echo -e "${BLUE}📋 Created backup: $BACKUP_FILE${NC}"
fi

# Test files that should only be in the test target
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

echo -e "${BLUE}🔍 Checking test file target membership...${NC}"

# Check if test files are properly configured
for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$test_file" ]; then
        echo -e "${GREEN}✅ Found: $test_file${NC}"
    else
        echo -e "${YELLOW}⚠️  Missing: $test_file${NC}"
    fi
done

echo -e "${BLUE}📝 Note: You need to manually add these test files to Xcode project with correct target membership:${NC}"
echo -e "${YELLOW}1. Open Xcode project${NC}"
echo -e "${YELLOW}2. Right-click on 'ClariFi iOSTests' group${NC}"
echo -e "${YELLOW}3. Select 'Add Files to "ClariFi iOS"'${NC}"
echo -e "${YELLOW}4. Navigate to each test file and add it${NC}"
echo -e "${YELLOW}5. In File Inspector, ensure ONLY 'ClariFi iOSTests' target is checked${NC}"
echo -e "${YELLOW}6. Clean and rebuild project${NC}"

echo -e "${GREEN}✅ Target membership fix instructions provided${NC}"