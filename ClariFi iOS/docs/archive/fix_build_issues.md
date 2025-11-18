# Build Issues Fix Guide

## Problem
The build is failing because test files are being compiled as part of the main app target instead of the test target. This causes "no such module 'XCTest'" errors.

## Root Cause
Test files in the `ClariFi_iOSTests` folder are incorrectly included in the main app target compilation.

## Solution Steps

### 1. Fix Target Membership in Xcode

1. Open your project in Xcode
2. Select each test file in the `ClariFi_iOSTests` folder
3. In the File Inspector (right panel), check the "Target Membership" section
4. **Uncheck** the main app target (`ClariFi iOS`)
5. **Check** only the test target (`ClariFi iOSTests`)

### Files to Fix:
- `ClariFi_iOSTests/CoreDataModelTests.swift`
- `ClariFi_iOSTests/DataEncryptionTests.swift`
- `ClariFi_iOSTests/DataValidationTests.swift`
- `ClariFi_iOSTests/OCRParsingIntegrationTests.swift`
- `ClariFi_iOSTests/OCRServiceTests.swift`
- `ClariFi_iOSTests/PrivacyControlsTests.swift`
- `ClariFi_iOSTests/RepositoryEdgeCaseTests.swift`
- `ClariFi_iOSTests/RepositoryTests.swift`
- `ClariFi_iOSTests/TransactionParserTests.swift`

### 2. Alternative: Quick Fix via Project Navigator

1. In Xcode, select the project file (top of navigator)
2. Select the main app target (`ClariFi iOS`)
3. Go to "Build Phases" tab
4. Expand "Compile Sources"
5. Remove any test files that appear in this list
6. They should only be in the test target's "Compile Sources"

### 3. Verify the Fix

After making these changes:
1. Clean the build folder (Product → Clean Build Folder)
2. Try building again (⌘+B)
3. The "no such module 'XCTest'" errors should be resolved

## Expected Result

Once fixed, you should be able to:
- Build the main app successfully
- Run the app in the simulator
- Test the statement upload functionality
- Run unit tests separately

## Additional Notes

- Test files should never be part of the main app target
- XCTest framework is only available in test targets
- This is a common issue when adding test files to a project

If you continue to have issues after following these steps, try:
1. Restarting Xcode
2. Deleting derived data
3. Clean build folder and rebuild