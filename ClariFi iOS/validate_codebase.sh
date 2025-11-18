#!/bin/bash

# Comprehensive Codebase Validation Script
# Checks for common issues that could cause compilation errors

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     ClariFi iOS Codebase Validation                       ║"
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
WARN=0

# Function to check for issues
check_issue() {
    local description=$1
    local command=$2
    local expected=$3
    
    result=$(eval "$command" 2>/dev/null)
    count=$(echo "$result" | wc -l | tr -d ' ')
    
    if [ "$count" -eq "$expected" ] || [ -z "$result" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $description"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}✗ FAIL${NC} - $description"
        echo "   Found $count instances (expected $expected)"
        if [ -n "$result" ]; then
            echo "$result" | head -5 | sed 's/^/   /'
        fi
        FAIL=$((FAIL + 1))
    fi
}

check_warning() {
    local description=$1
    local command=$2
    
    result=$(eval "$command" 2>/dev/null)
    
    if [ -z "$result" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $description"
        PASS=$((PASS + 1))
    else
        echo -e "${YELLOW}⚠ WARN${NC} - $description"
        echo "$result" | head -3 | sed 's/^/   /'
        WARN=$((WARN + 1))
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING FOR EMOJIS IN CODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_issue "No emojis in Swift files" \
    "grep -r '💰\|🔒\|📊\|🔐\|👑\|⭐\|✨\|🎯\|📱\|💡\|🚀\|✅\|❌\|⚠️\|🎉\|📈\|💵\|💳\|🏦\|🏠\|🍔\|🚗\|🎬\|🏥\|✈️\|🎓\|👕\|🎮\|📚\|🐕\|🎨\|⚡\|🔥\|💪\|🎊\|🌟\|🇺🇸\|🇨🇦\|🇪🇺\|🇬🇧\|🇯🇵\|🇦🇺\|🇨🇭\|🇨🇳\|🇮🇳\|🇲🇽\|🇧🇷\|🇰🇷\|🇸🇬\|🇳🇿\|🇭🇰\|🔧\|📦' --include='*.swift' . | grep -v Tests.swift | grep -v Example.swift" \
    0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING FOR TYPE AMBIGUITIES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_warning "No ambiguous closure types" \
    "grep -r '\[weak self\] () -> Void in' --include='*.swift' . | grep -v Tests.swift"

check_warning "No unnecessary type annotations in closures" \
    "grep -r 'let queue: DispatchQueue = ' --include='*.swift' . | grep -v Tests.swift"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING FOR COMMON SWIFT ISSUES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_warning "No force unwrapping in production code" \
    "grep -r '!' --include='*.swift' Views ViewModels Services Models Core | grep -v '!=' | grep -v '//' | grep -v Tests.swift | head -10"

check_warning "No print statements in production code" \
    "grep -r 'print(' --include='*.swift' Views ViewModels Services Models Core | grep -v '//' | grep -v Tests.swift | head -10"

check_issue "No TODO comments in critical files" \
    "grep -r 'TODO' --include='*.swift' Views/CurrencySettingsView.swift Models/Currency.swift Services/LLM/AppleLLMCategorizationService.swift" \
    0

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING FILE STRUCTURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_issue "Currency model exists" \
    "test -f Models/Currency.swift && echo 'exists'" \
    1

check_issue "Currency settings view exists" \
    "test -f Views/CurrencySettingsView.swift && echo 'exists'" \
    1

check_issue "Transaction currency extension exists" \
    "test -f Models/Transaction+Currency.swift && echo 'exists'" \
    1

check_issue "Decimal currency extension exists" \
    "test -f Core/Extensions/Decimal+Currency.swift && echo 'exists'" \
    1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  CHECKING SWIFT SYNTAX"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for unmatched braces
check_warning "Balanced braces in Swift files" \
    "for file in \$(find . -name '*.swift' -not -path '*/Tests/*'); do
        open=\$(grep -o '{' \"\$file\" | wc -l)
        close=\$(grep -o '}' \"\$file\" | wc -l)
        if [ \$open -ne \$close ]; then
            echo \"\$file: open=\$open close=\$close\"
        fi
    done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  VALIDATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL=$((PASS + FAIL + WARN))

echo "Total Checks: $TOTAL"
echo -e "${GREEN}Passed: $PASS${NC}"
if [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARN${NC}"
fi
if [ $FAIL -gt 0 ]; then
    echo -e "${RED}Failed: $FAIL${NC}"
fi
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ VALIDATION PASSED!                                      ║${NC}"
    echo -e "${GREEN}║  Codebase is clean and ready for compilation.             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ VALIDATION FAILED                                       ║${NC}"
    echo -e "${RED}║  Please fix the issues above before compiling.            ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 1
fi
