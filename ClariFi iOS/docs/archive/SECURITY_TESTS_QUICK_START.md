# Security Tests Quick Start Guide

## 🚀 Quick Run

Run all security tests with one command:
```bash
./run_security_tests.sh
```

## 📋 What Gets Tested

### ✅ Encryption Service (34 tests)
- Key management and Keychain storage
- Data encryption/decryption with AES-GCM
- String encryption with Unicode support
- Secure storage operations
- Error handling

### ✅ Biometric Authentication (25 tests)
- Face ID/Touch ID availability
- Authentication settings and timeout
- Enable/disable flows
- Error handling

### ✅ Secure File Manager (30 tests)
- Temporary file creation with protection
- Secure deletion with overwriting
- Automatic cleanup on lifecycle events
- Performance with large batches

## 🎯 Requirements Covered

- **8.1**: Data encryption using iOS Keychain and Data Protection
- **8.2**: Biometric authentication for app access
- **8.5**: Secure temporary file handling

## 📊 Test Results

**Total Tests:** 89 comprehensive unit tests
**Coverage:** All security requirements (8.1, 8.2, 8.5)

## 🔧 Individual Test Suites

### Run Encryption Tests Only
```bash
xcodebuild test -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/EncryptionServiceTests
```

### Run Biometric Tests Only
```bash
xcodebuild test -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/BiometricAuthServiceTests
```

### Run File Manager Tests Only
```bash
xcodebuild test -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/SecureFileManagerTests
```

## 📁 Test Files Location

```
Tests/
├── EncryptionServiceTests.swift      (34 tests)
├── BiometricAuthServiceTests.swift   (25 tests)
└── SecureFileManagerTests.swift      (30 tests)
```

## 📖 Documentation

- **SECURITY_TESTS_IMPLEMENTATION.md** - Detailed test documentation
- **SECURITY_TESTS_SUMMARY.md** - Complete test summary
- **run_security_tests.sh** - Automated test runner

## ⚠️ Important Notes

1. **Simulator vs Device**: Biometric tests verify settings but may not trigger actual Face ID/Touch ID in simulator
2. **Keychain**: Tests clean up Keychain items automatically
3. **File System**: Temporary files are cleaned up after tests
4. **Isolation**: Each test runs in isolation with clean state

## ✨ Test Highlights

- **Large Data**: Tests handle files >1MB
- **Unicode**: Full international character support
- **Performance**: Batch operations with 100+ files
- **Error Handling**: All error scenarios covered
- **Edge Cases**: Empty data, missing files, corrupted data

## 🎉 Success Criteria

All tests should pass with:
- ✅ Encryption/decryption working correctly
- ✅ Biometric settings persisting properly
- ✅ Files created with proper protection
- ✅ Secure deletion overwriting data
- ✅ Automatic cleanup functioning

## 🐛 Troubleshooting

If tests fail:
1. Check Xcode version compatibility
2. Verify iOS Simulator is available
3. Ensure test target has proper entitlements
4. Check Keychain access permissions
5. Review test output for specific failures

## 📞 Need Help?

See detailed documentation in:
- `SECURITY_TESTS_IMPLEMENTATION.md` for test details
- `SECURITY_TESTS_SUMMARY.md` for coverage overview
