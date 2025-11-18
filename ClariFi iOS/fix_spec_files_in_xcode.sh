#!/bin/bash

# Fix Xcode build error by removing spec files from Copy Bundle Resources
# These files should not be included in the app bundle

echo "Fixing Xcode project to exclude spec files from bundle..."

# The spec files causing conflicts:
# - .kiro/specs/*/design.md
# - .kiro/specs/*/requirements.md  
# - .kiro/specs/*/tasks.md

# Solution: Remove these files from the Xcode project target membership
# They should remain in the file system but not be copied to the app bundle

echo ""
echo "The following files are causing build conflicts:"
echo "  - .kiro/specs/additional-ux-improvements/design.md"
echo "  - .kiro/specs/additional-ux-improvements/requirements.md"
echo "  - .kiro/specs/additional-ux-improvements/tasks.md"
echo "  - .kiro/specs/critical-ux-fixes/design.md"
echo "  - .kiro/specs/critical-ux-fixes/requirements.md"
echo "  - .kiro/specs/critical-ux-fixes/tasks.md"
echo ""
echo "These files need to be removed from the Xcode target's 'Copy Bundle Resources' phase."
echo ""
echo "To fix this manually in Xcode:"
echo "1. Open the project in Xcode"
echo "2. Select the project in the navigator"
echo "3. Select the 'ClariFi iOS' target"
echo "4. Go to 'Build Phases' tab"
echo "5. Expand 'Copy Bundle Resources'"
echo "6. Find and remove all .md files from .kiro/specs/ directories"
echo "7. Clean build folder (Cmd+Shift+K)"
echo "8. Build again (Cmd+B)"
echo ""
echo "Alternatively, you can exclude the entire .kiro directory from the target:"
echo "1. Select any .kiro file in the Project Navigator"
echo "2. In the File Inspector (right panel), uncheck 'Target Membership' for 'ClariFi iOS'"
echo ""

# Try to build and show the result
echo "Attempting to build..."
xcodebuild -project "../ClariFi iOS.xcodeproj" -scheme "ClariFi iOS" -configuration Debug -sdk iphonesimulator clean build 2>&1 | grep -E "(error:|warning:|Build succeeded|BUILD FAILED)" | head -20
