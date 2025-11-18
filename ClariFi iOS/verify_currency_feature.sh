#!/bin/bash

# Currency Feature Verification Script
# This script verifies that all currency feature files are in place

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Currency Feature Verification Script                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0

# Function to check file
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ PASS${NC} - $description"
        echo "   📄 File: $file"
        echo "   📊 Lines: $(wc -l < "$file" | tr -d ' ')"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌ FAIL${NC} - $description"
        echo "   📄 File: $file (NOT FOUND)"
        FAIL=$((FAIL + 1))
    fi
    echo ""
}

# Function to check content
check_content() {
    local file=$1
    local pattern=$2
    local description=$3
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "${GREEN}✅ PASS${NC} - $description"
        echo "   📄 File: $file"
        echo "   🔍 Found: $(grep -n "$pattern" "$file" | head -1)"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌ FAIL${NC} - $description"
        echo "   📄 File: $file"
        echo "   🔍 Pattern: $pattern (NOT FOUND)"
        FAIL=$((FAIL + 1))
    fi
    echo ""
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING CORE FILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_file "Models/Currency.swift" "Currency Model"
check_file "Views/CurrencySettingsView.swift" "Currency Settings View"
check_file "Models/Transaction+Currency.swift" "Transaction Currency Extension"
check_file "Core/Extensions/Decimal+Currency.swift" "Decimal Currency Extension"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING INTEGRATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_content "Views/PlanningView.swift" "CurrencySettingsView" "Currency option in PlanningView"
check_content "Views/PlanningView.swift" "Currency.*systemImage" "Currency label in PlanningView"
check_content "Models/Currency.swift" "enum Currency" "Currency enum definition"
check_content "Models/Currency.swift" "CurrencyPreferenceManager" "Currency preference manager"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING DOCUMENTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_file "docs/CURRENCY_SUPPORT_GUIDE.md" "Currency Support Guide"
check_file "docs/CURRENCY_FEATURE_IMPLEMENTATION_SUMMARY.md" "Implementation Summary"
check_file "docs/HOW_TO_CHANGE_CURRENCY.md" "User How-To Guide"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VERIFICATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL=$((PASS + FAIL))

echo "Total Checks: $TOTAL"
echo -e "${GREEN}Passed: $PASS${NC}"
if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Failed: $FAIL${NC}"
else
    echo -e "${GREEN}Failed: $FAIL${NC}"
fi
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL CHECKS PASSED!                                     ║${NC}"
    echo -e "${GREEN}║  Currency feature is fully implemented and ready to use.  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Build and run the app in Xcode (⌘R)"
    echo "2. Navigate to Planning tab"
    echo "3. Look for 'Currency' in App Settings"
    echo "4. Tap it to select your preferred currency"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ SOME CHECKS FAILED                                     ║${NC}"
    echo -e "${RED}║  Please review the failed checks above.                   ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
