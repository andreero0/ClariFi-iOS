#!/bin/bash

# Script to help identify and fix test file target membership issues
# This script analyzes the Xcode project and reports files that may have incorrect target membership

echo "🔍 Analyzing Xcode Project for Test Target Membership Issues..."
echo ""

PROJECT_FILE="../ClariFi iOS.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Could not find project file at $PROJECT_FILE"
    exit 1
fi

echo "📋 Files in Tests/ directory that should ONLY be in test target:"
echo ""

# Find all Swift files in Tests directory
find Tests -name "*.swift" -type f | while read file; do
    filename=$(basename "$file")
    echo "  - $file"
done

echo ""
echo "⚠️  MANUAL ACTION REQUIRED:"
echo ""
echo "For each file listed above, you need to:"
echo "1. Open the Xcode project"
echo "2. Select the file in Project Navigator"
echo "3. Open File Inspector (right sidebar)"
echo "4. In 'Target Membership' section:"
echo "   - UNCHECK 'ClariFi iOS' (main app target)"
echo "   - CHECK 'ClariFi iOSTests' (test target)"
echo ""
echo "Specifically, these files are causing issues:"
echo "  ❌ Tests/Mocks/MockRepositories.swift"
echo "  ❌ Tests/Mocks/MockServices.swift"
echo ""
echo "After fixing:"
echo "  1. Clean build folder (Cmd+Shift+K)"
echo "  2. Rebuild project"
echo "  3. Run tests (Cmd+U)"
echo ""
echo "📖 See TEST_TARGET_FIX_GUIDE.md for detailed instructions"
