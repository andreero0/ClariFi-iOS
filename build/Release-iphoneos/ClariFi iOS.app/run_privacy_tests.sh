#!/bin/bash

# Script to run privacy control tests

echo "Running Privacy Manager Tests..."
echo "================================"

# Check if we're in the right directory
if [ ! -d "ClariFi iOSTests" ]; then
    echo "Error: ClariFi iOSTests directory not found"
    echo "Please run this script from the project root"
    exit 1
fi

# Find the Xcode project
PROJECT_PATH="../ClariFi iOS.xcodeproj"

if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Xcode project not found at $PROJECT_PATH"
    exit 1
fi

echo "Found Xcode project at: $PROJECT_PATH"
echo ""

# Run the tests
echo "Running tests..."
xcodebuild test \
    -project "$PROJECT_PATH" \
    -scheme "ClariFi iOS" \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:ClariFi_iOSTests/PrivacyManagerTests \
    | xcpretty || true

echo ""
echo "================================"
echo "Test run complete!"
echo ""
echo "To run specific tests, use:"
echo "  xcodebuild test -project '$PROJECT_PATH' -scheme 'ClariFi iOS' -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ClariFi_iOSTests/PrivacyManagerTests/testExportUserDataWithTransactions"
