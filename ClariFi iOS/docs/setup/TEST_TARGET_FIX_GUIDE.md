# Test Target Membership Fix Guide

## Problem

The test mock files (`MockRepositories.swift` and `MockServices.swift`) are incorrectly included in the main app target (`ClariFi iOS`), causing type conflicts and build failures.

### Error Symptoms:
```
warning: file 'MockRepositories.swift' is part of module 'ClariFi_iOS'; ignoring import
warning: file 'MockServices.swift' is part of module 'ClariFi_iOS'; ignoring import
error: Invalid redeclaration of 'BudgetAlert'
error: Invalid redeclaration of 'BudgetStatus'
error: Invalid redeclaration of 'CategoryStatus'
```

## Root Cause

Mock files define types (`BudgetStatus`, `BudgetAlert`, `CategoryStatus`) that already exist in production code (`BudgetMonitoringService.swift`). When mock files are compiled as part of the main app target, Swift sees duplicate type definitions and fails to compile.

## Solution

Remove mock files from the main app target membership. They should ONLY be part of the test target.

### Steps to Fix:

1. **Open Xcode** and navigate to the project

2. **Select `MockRepositories.swift`** in the Project Navigator
   - Location: `Tests/Mocks/MockRepositories.swift`

3. **Open the File Inspector** (right sidebar, first tab)

4. **Check "Target Membership" section**:
   - ❌ **UNCHECK** `ClariFi iOS` (main app target)
   - ✅ **CHECK** `ClariFi iOSTests` (test target)

5. **Repeat for `MockServices.swift`**:
   - Location: `Tests/Mocks/MockServices.swift`
   - ❌ **UNCHECK** `ClariFi iOS`
   - ✅ **CHECK** `ClariFi iOSTests`

6. **Clean Build Folder**:
   - Menu: Product → Clean Build Folder (Cmd+Shift+K)

7. **Rebuild and Run Tests**:
   - Menu: Product → Test (Cmd+U)

## Verification

After fixing, you should see:
- ✅ No warnings about files being part of module
- ✅ No "invalid redeclaration" errors
- ✅ Tests compile and run successfully

## Why This Happened

When files are added to an Xcode project, Xcode automatically selects target membership. The mock files were likely added with the main app target selected, causing them to be included in both targets.

## Prevention

When adding test files in the future:
1. Always verify target membership in the File Inspector
2. Test files should ONLY be in test targets
3. Production code should ONLY be in the main app target

## Alternative: Script-Based Fix

If you prefer to fix this programmatically, you can modify the Xcode project file directly, but this is more error-prone and not recommended unless you're comfortable with pbxproj file format.

---

**Priority**: CRITICAL - Blocks all testing  
**Estimated Time**: 2 minutes  
**Difficulty**: Easy (just unchecking boxes)
