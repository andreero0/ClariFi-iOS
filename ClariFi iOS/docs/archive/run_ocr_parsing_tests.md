# OCR and Parsing Tests

This document describes the unit tests created for task 2.3: "Write unit tests for OCR and parsing".

## Test Files Created

### 1. OCRServiceTests.swift
Tests the Vision OCR service implementation with focus on:
- **OCR Accuracy**: Tests with various document types and quality levels
- **Image Processing**: Tests preprocessing steps and image quality handling
- **PDF Processing**: Tests PDF document parsing and multi-page handling
- **Confidence Scoring**: Validates confidence calculations for different text qualities
- **Error Handling**: Tests various error conditions and edge cases
- **Performance**: Ensures reasonable processing times
- **Bounding Boxes**: Validates text location detection

Key test methods:
- `testProcessImage_SimpleText()` - Basic OCR functionality
- `testProcessImage_TransactionText()` - OCR with financial data
- `testProcessDocument_PDFWithText()` - PDF processing
- `testConfidenceScoring_HighQualityText()` - Confidence validation
- `testErrorHandling_OCRErrors()` - Error condition handling

### 2. TransactionParserTests.swift
Tests the Smart Transaction Parser with focus on:
- **Transaction Parsing**: Various statement formats and layouts
- **Date Parsing**: Multiple date formats and partial dates
- **Amount Parsing**: Currency formatting and negative amounts
- **Merchant Parsing**: Name cleanup and standardization
- **Confidence Scoring**: Field-level and overall confidence calculation
- **Category Prediction**: Automatic categorization based on merchant patterns
- **Transaction Type Detection**: Fee, interest, transfer, etc. identification
- **Error Handling**: Invalid input and edge cases
- **Learning**: User correction integration

Key test methods:
- `testParseTransactions_SimpleFormat()` - Basic parsing functionality
- `testParseTransactions_BankOfAmericaFormat()` - Bank-specific format handling
- `testDateParsing_VariousFormats()` - Date format flexibility
- `testConfidenceScoring_HighConfidenceTransaction()` - Confidence validation
- `testCategoryPrediction_CommonMerchants()` - Auto-categorization
- `testImproveAccuracy_UserCorrections()` - Learning from corrections

### 3. OCRParsingIntegrationTests.swift
Tests the complete OCR → Parsing pipeline with focus on:
- **End-to-End Processing**: Complete document processing workflow
- **Confidence Correlation**: How OCR confidence affects parsing confidence
- **Error Propagation**: How errors flow through the pipeline
- **Performance Integration**: Complete pipeline timing
- **Real-world Scenarios**: Mixed quality documents and noisy statements

Key test methods:
- `testCompleteOCRParsingPipeline_BankStatement()` - Full pipeline test
- `testConfidenceCorrelation_OCRToParser()` - Confidence relationship
- `testRealWorldScenario_MixedQualityStatement()` - Real-world conditions
- `testPerformance_CompleteOCRParsingPipeline()` - Performance validation

## Requirements Coverage

The tests address all requirements specified in task 2.3:

### ✅ Test OCR accuracy with sample documents
- Tests with various document types (images, PDFs)
- Tests with different text qualities and formats
- Tests with realistic bank statement layouts
- Validates confidence scoring for accuracy assessment

### ✅ Test transaction parsing with various formats
- Tests multiple bank statement formats (Bank of America, Chase, Wells Fargo, etc.)
- Tests different date formats (MM/DD/YYYY, MM/DD/YY, Month DD, YYYY)
- Tests various amount formats ($X.XX, X.XX, $X,XXX.XX)
- Tests merchant name variations and cleanup rules

### ✅ Test confidence scoring and error handling
- Validates confidence calculations at field level (date, merchant, amount)
- Tests overall confidence scoring algorithms
- Tests error conditions (no text found, low confidence, invalid formats)
- Tests error propagation through the pipeline
- Validates error message clarity and usefulness

## Running the Tests

To run these tests in Xcode:

1. Open the ClariFi iOS project in Xcode
2. Navigate to the Test Navigator (⌘6)
3. Run individual test files or specific test methods
4. Or use the command line:

```bash
# Run all OCR and parsing tests
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:ClariFi_iOSTests/OCRServiceTests -only-testing:ClariFi_iOSTests/TransactionParserTests -only-testing:ClariFi_iOSTests/OCRParsingIntegrationTests

# Run specific test class
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:ClariFi_iOSTests/OCRServiceTests

# Run specific test method
xcodebuild test -scheme ClariFi_iOS -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:ClariFi_iOSTests/OCRServiceTests/testProcessImage_SimpleText
```

## Test Coverage Summary

- **OCR Service**: 15+ test methods covering accuracy, performance, and error handling
- **Transaction Parser**: 20+ test methods covering parsing, confidence, and learning
- **Integration**: 10+ test methods covering end-to-end scenarios
- **Total**: 45+ comprehensive test methods

The tests use realistic sample data and cover both happy path scenarios and edge cases, ensuring robust validation of the OCR and parsing functionality as required by the task specifications.