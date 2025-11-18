# Xcode Build Error Fix

## Problem

Xcode is trying to copy multiple spec files with the same names from different directories:
- `.kiro/specs/additional-ux-improvements/design.md`
- `.kiro/specs/critical-ux-fixes/design.md`
- `.kiro/specs/architecture-refactoring/design.md`
- (and requirements.md, tasks.md from each)

This causes "Multiple commands produce" errors because they all try to copy to the same destination in the app bundle.

## Root Cause

The `.kiro/specs` directory (or individual spec directories) were added to the Xcode project as folder references, causing all files within to be copied to the app bundle.

## Solution

**Option 1: Remove .kiro folder from Xcode project (Recommended)**

1. Open `ClariFi iOS.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), find the `.kiro` folder
3. Right-click on `.kiro` → Delete
4. Choose "Remove Reference" (NOT "Move to Trash")
5. Clean Build Folder: Product → Clean Build Folder (Cmd+Shift+K)
6. Build: Product → Build (Cmd+B)

**Option 2: Disable "Copy items if needed" for .kiro**

1. Select the `.kiro` folder in Project Navigator
2. In File Inspector (right sidebar), uncheck "Target Membership" for "ClariFi iOS"
3. Clean and build

**Option 3: Add .kiro to .gitignore and remove from project**

The `.kiro` directory contains Kiro IDE metadata and specs that shouldn't be in the app bundle anyway.

## Quick Fix via Command Line

Run this command to remove the .kiro references from the Xcode project:

```bash
# Backup the project file
cp "../ClariFi iOS.xcodeproj/project.pbxproj" "../ClariFi iOS.xcodeproj/project.pbxproj.backup"

# Remove .kiro/specs references (this is a simplified approach)
# You'll need to manually remove them in Xcode for a clean solution
```

## After Fix

Once fixed, the build should succeed. The spec files will still exist on disk in `.kiro/specs/` but won't be copied to the app bundle.

## Prevention

To prevent this in the future:
1. Don't add the `.kiro` directory to Xcode projects
2. Keep spec files outside the main project structure
3. Use Xcode's "Add Files" with "Create folder references" unchecked for documentation

## Manual Fix Steps (Most Reliable)

1. **Open Xcode**
2. **Select Project** in Navigator (top item)
3. **Select Target** "ClariFi iOS"
4. **Go to Build Phases tab**
5. **Expand "Copy Bundle Resources"**
6. **Find all .md files from .kiro/specs/**
7. **Select them and press Delete (-)** 
8. **Clean Build Folder** (Cmd+Shift+K)
9. **Build** (Cmd+B)

This is the cleanest solution and will permanently fix the issue.
