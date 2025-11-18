#!/bin/bash

# Script to run security tests for ClariFi iOS
# Tests encryption, biometric authentication, and secure file handling

echo "🔒 Running ClariFi Security Tests..."
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

# Find the scheme name
SCHEME="ClariFi iOS"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"
PROJECT_PATH="../ClariFi iOS.xcodeproj"

echo "📱 Using destination: $DESTINATION"
echo "📁 Using project: $PROJECT_PATH"
echo ""

# Function to run a test suite
run_test_suite() {
    local test_name=$1
    local test_target=$2
    
    echo -e "${YELLOW}Running $test_name...${NC}"
    
    xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -only-testing:"$test_target" \
        2>&1 | grep -E "Test Suite|Test Case|passed|failed|error"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name passed${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ $test_name failed${NC}"
        echo ""
        return 1
    fi
}

# Track overall success
OVERALL_SUCCESS=0

# Run Encryption Service Tests
run_test_suite "Encryption Service Tests" "ClariFi_iOSTests/EncryptionServiceTests"
if [ $? -ne 0 ]; then OVERALL_SUCCESS=1; fi

# Run Biometric Auth Service Tests
run_test_suite "Biometric Auth Service Tests" "ClariFi_iOSTests/BiometricAuthServiceTests"
if [ $? -ne 0 ]; then OVERALL_SUCCESS=1; fi

# Run Secure File Manager Tests
run_test_suite "Secure File Manager Tests" "ClariFi_iOSTests/SecureFileManagerTests"
if [ $? -ne 0 ]; then OVERALL_SUCCESS=1; fi

# Summary
echo "=================================="
if [ $OVERALL_SUCCESS -eq 0 ]; then
    echo -e "${GREEN}🎉 All security tests passed!${NC}"
    echo ""
    echo "✅ Encryption and decryption functionality verified"
    echo "✅ Biometric authentication flows tested"
    echo "✅ Secure file handling and cleanup verified"
else
    echo -e "${RED}❌ Some security tests failed${NC}"
    echo ""
    echo "Please review the test output above for details."
fi

echo ""
echo "Test Coverage:"
echo "  • Requirements 8.1: Data encryption ✓"
echo "  • Requirements 8.2: Biometric authentication ✓"
echo "  • Requirements 8.5: Secure file handling ✓"

exit $OVERALL_SUCCESS
