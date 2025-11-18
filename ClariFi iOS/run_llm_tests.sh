#!/bin/bash

# Run LLM Categorization Service Tests
echo "Running LLM Categorization Service Tests..."
echo "============================================="

xcodebuild test \
  -project "../ClariFi iOS.xcodeproj" \
  -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' \
  -only-testing:ClariFi_iOSTests/LLMCategorizationServiceTests \
  2>&1 | grep -E "(Test Suite|Test Case|passed|failed|error:|Testing)" || \
xcodebuild test \
  -project "../ClariFi iOS.xcodeproj" \
  -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' \
  2>&1 | grep -E "LLMCategorizationServiceTests"

echo ""
echo "Test run complete!"
