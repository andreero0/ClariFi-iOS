# UI Tests for Statement Upload Flow

## Overview

This document describes the comprehensive UI tests created for the statement upload and transaction review flow in ClariFi iOS. These tests cover the complete user journey from document selection through transaction confirmation, including error handling and recovery scenarios.

## Test Files

### 1. StatementUploadFlowTests.swift

Tests the complete statement upload flow including document selection, processing, and transaction parsing.

#### Test Coverage:

**Document Selection Tests:**
- `testShowDocumentPicker_UpdatesState` - Verifies document picker state management
- `testShowCamera_UpdatesState` - Verifies camera interface state management
- `testShowPhotoLibrary_UpdatesState` - Verifies photo library picker state management

**Document Processing Flow Tests:**
- `testProcessDocument_ValidPDF_Success` - Tests successful PDF processing
- `testProcessDocument_ValidImage_Success` - Tests successful image processing
- `testProcessDocument_DuplicateStatement_ShowsError` - Tests duplicate detection
- `testProcessDocument_InvalidFile_ShowsError` - Tests invalid file rejection
- `testProcessDocument_FileTooLarge_ShowsError` - Tests file size validation
- `testProcessDocument_OCRFailure_ShowsError` - Tests OCR error handling
- `testProcessDocument_ParsingFailure_ShowsError` - Tests parsing error handling

**Processing Progress Tests:**
- `testProcessDocument_UpdatesProgress` - Verifies progress updates during processing
- `testCancelProcessing_StopsProcessing` - Tests cancellation functionality

**Image Processing Tests:**
- `testProcessImage_ValidImage_Success` - Tests camera/photo library image processing
- `testProcessImage_InvalidImage_ShowsError` - Tests invalid image handling

**Transaction Confirmation Tests:**
- `testConfirmTransactions_SavesSuccessfully` - Tests successful transaction save
- `testConfirmTransactions_SaveFailure_ShowsError` - Tests save error handling

**Reset and Clear Tests:**
- `testResetUpload_ClearsState` - Tests state reset functionality
- `testClearError_RemovesError` - Tests error clearing

**Statement Format Detection Tests:**
- `testProcessDocument_DetectsStatementFormat` - Tests automatic format detection

### 2. TransactionReviewFlowTests.swift

Tests the transaction review and correction interface functionality.

#### Test Coverage:

**Transaction Loading Tests:**
- `testSetTransactions_LoadsTransactions` - Tests transaction loading
- `testSetTransactions_ClearsEditedTransactions` - Tests state clearing on new load

**Transaction Update Tests:**
- `testUpdateTransaction_StoresEdit` - Tests edit storage
- `testUpdateTransaction_SubmitsCorrection` - Tests correction submission for learning
- `testUpdateTransaction_MerchantChange_CorrectFeedback` - Tests merchant correction feedback
- `testUpdateTransaction_AmountChange_CorrectFeedback` - Tests amount correction feedback

**Batch Edit Tests:**
- `testApplyBatchChanges_UpdatesCategory` - Tests single batch edit
- `testApplyBatchChanges_MultipleTransactions` - Tests batch editing multiple transactions

**Final Transactions Tests:**
- `testGetFinalTransactions_NoEdits_ReturnsOriginal` - Tests unedited transaction retrieval
- `testGetFinalTransactions_WithEdits_ReturnsEdited` - Tests edited transaction retrieval

**Transaction Stats Tests:**
- `testGetTransactionStats_CalculatesCorrectly` - Tests statistics calculation
- `testGetTransactionStats_CountsLowConfidence` - Tests low confidence counting
- `testGetTransactionStats_CountsEdits` - Tests edit counting
- `testGetTransactionStats_CalculatesAverage` - Tests average calculation

**Validation Tests:**
- `testValidateTransactions_NoErrors` - Tests valid transactions
- `testValidateTransactions_MissingDate` - Tests missing date detection
- `testValidateTransactions_MissingMerchant` - Tests missing merchant detection
- `testValidateTransactions_MissingAmount` - Tests missing amount detection
- `testValidateTransactions_NegativeAmount` - Tests negative amount detection
- `testValidateTransactions_UnusuallyLargeAmount` - Tests large amount detection
- `testValidateTransactions_MultipleErrors` - Tests multiple error detection

### 3. UploadErrorRecoveryTests.swift

Tests error states and recovery flows throughout the upload process.

#### Test Coverage:

**OCR Error Recovery Tests:**
- `testOCRError_NoTextFound_ShowsError` - Tests no text found error
- `testOCRError_LowConfidence_ShowsError` - Tests low confidence error
- `testOCRError_ProcessingFailed_ShowsError` - Tests processing failure error
- `testOCRError_MemoryLimitExceeded_ShowsError` - Tests memory limit error
- `testOCRError_UnsupportedDocumentType_ShowsError` - Tests unsupported type error

**Parsing Error Recovery Tests:**
- `testParsingError_NoTransactionsFound_ShowsError` - Tests no transactions error
- `testParsingError_InvalidFormat_ShowsError` - Tests invalid format error
- `testParsingError_InsufficientData_ShowsError` - Tests insufficient data error

**Repository Error Recovery Tests:**
- `testRepositoryError_SaveFailure_ShowsError` - Tests save failure error
- `testRepositoryError_CoreDataError_ShowsError` - Tests Core Data error

**Error Recovery Flow Tests:**
- `testErrorRecovery_ClearError_AllowsRetry` - Tests error clearing and retry
- `testErrorRecovery_ResetAfterError_ClearsState` - Tests state reset after error
- `testErrorRecovery_CancelDuringError_ClearsProcessing` - Tests cancellation during error

**Upload Error Tests:**
- `testUploadError_DuplicateStatement_PreventsDuplicate` - Tests duplicate prevention
- `testUploadError_InvalidFile_RejectsFile` - Tests invalid file rejection

**Error Message Tests:**
- `testErrorMessages_HaveDescriptions` - Tests UploadError descriptions
- `testErrorMessages_OCRErrors_HaveDescriptions` - Tests OCRError descriptions
- `testErrorMessages_ParsingErrors_HaveDescriptions` - Tests ParsingError descriptions

**Concurrent Error Tests:**
- `testConcurrentErrors_OnlyOneProcessingAtTime` - Tests concurrent processing handling

## Requirements Coverage

These tests fulfill the requirements specified in task 3.3:

### Requirement 1.1: Statement Upload and Processing
- ✅ Document selection (PDF, JPG, PNG, HEIC)
- ✅ Local OCR processing
- ✅ Confidence scoring
- ✅ Duplicate detection
- ✅ File validation

### Requirement 1.3: Transaction Review
- ✅ Confidence indicators
- ✅ Transaction editing
- ✅ Batch editing
- ✅ Field validation
- ✅ User corrections

### Requirement 1.6: Error Handling
- ✅ OCR failures
- ✅ Parsing failures
- ✅ Save failures
- ✅ Invalid files
- ✅ Error recovery flows
- ✅ User feedback

## Mock Services

The tests use mock implementations of key services:

### MockOCRService
- Simulates OCR processing with configurable delays
- Can simulate various error conditions
- Returns configurable mock results

### MockTransactionParserService
- Simulates transaction parsing
- Can simulate parsing errors
- Tracks correction submissions for learning

### MockTransactionRepository
- Simulates data persistence
- Can simulate save failures
- Tracks saved transactions

## Running the Tests

### Run All UI Flow Tests:
```bash
xcodebuild test -project "ClariFi iOS.xcodeproj" -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/StatementUploadFlowTests \
  -only-testing:ClariFi_iOSTests/TransactionReviewFlowTests \
  -only-testing:ClariFi_iOSTests/UploadErrorRecoveryTests
```

### Run Individual Test Suites:
```bash
# Statement Upload Flow Tests
xcodebuild test -project "ClariFi iOS.xcodeproj" -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/StatementUploadFlowTests

# Transaction Review Flow Tests
xcodebuild test -project "ClariFi iOS.xcodeproj" -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/TransactionReviewFlowTests

# Error Recovery Tests
xcodebuild test -project "ClariFi iOS.xcodeproj" -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/UploadErrorRecoveryTests
```

### Run Specific Test:
```bash
xcodebuild test -project "ClariFi iOS.xcodeproj" -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ClariFi_iOSTests/StatementUploadFlowTests/testProcessDocument_ValidPDF_Success
```

## Test Patterns

### Async Testing Pattern
All tests use Swift's modern async/await pattern:
```swift
func testExample() async {
    // Given
    let data = createTestData()
    
    // When
    await viewModel.processDocument(data, filename: "test.pdf", contentType: .pdf)
    
    // Wait for processing
    try? await Task.sleep(nanoseconds: 1_000_000_000)
    
    // Then
    await MainActor.run {
        XCTAssertFalse(viewModel.isProcessing)
    }
}
```

### Mock Service Pattern
Tests use dependency injection with mock services:
```swift
override func setUp() {
    super.setUp()
    
    mockOCRService = MockOCRService()
    mockParserService = MockTransactionParserService()
    mockRepository = MockTransactionRepository()
    
    viewModel = StatementUploadViewModel(
        ocrService: mockOCRService,
        parserService: mockParserService,
        transactionRepository: mockRepository
    )
}
```

### Error Testing Pattern
Error tests configure mocks to throw specific errors:
```swift
func testOCRError_NoTextFound_ShowsError() async {
    // Given
    mockOCRService.errorToThrow = OCRError.noTextFound
    
    // When
    await viewModel.processDocument(data, filename: "test.jpg", contentType: .jpeg)
    
    // Then
    await MainActor.run {
        XCTAssertNotNil(viewModel.error)
    }
}
```

## Test Metrics

- **Total Tests**: 60+
- **Test Files**: 3
- **Code Coverage**: Covers all major user flows and error scenarios
- **Requirements Coverage**: 100% of specified requirements (1.1, 1.3, 1.6)

## Maintenance Notes

### Adding New Tests
1. Follow the existing test structure and naming conventions
2. Use the established mock service pattern
3. Test both success and failure scenarios
4. Include async/await patterns for asynchronous operations
5. Clean up state in `tearDown()`

### Updating Tests
When updating ViewModels or Services:
1. Update corresponding mock implementations
2. Verify all existing tests still pass
3. Add new tests for new functionality
4. Update this documentation

## Known Limitations

1. **UI Testing**: These are ViewModel/logic tests, not full UI automation tests. For complete UI testing, consider adding XCUITest tests.
2. **Real OCR**: Tests use mocks and don't test actual Vision framework OCR accuracy.
3. **Performance**: Tests don't measure actual performance metrics, only functional correctness.
4. **Accessibility**: Accessibility testing should be done separately with XCUITest.

## Future Enhancements

1. Add XCUITest tests for complete UI automation
2. Add performance benchmarking tests
3. Add accessibility compliance tests
4. Add snapshot tests for UI components
5. Add integration tests with real OCR on sample documents
