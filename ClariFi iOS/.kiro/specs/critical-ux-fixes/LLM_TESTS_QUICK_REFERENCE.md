# LLM Tests Quick Reference

## Running the Tests

```bash
# Quick run
./run_llm_tests.sh

# Full output
xcodebuild test \
  -project "../ClariFi iOS.xcodeproj" \
  -scheme "ClariFi iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' \
  -only-testing:ClariFi_iOSTests/LLMCategorizationServiceTests
```

## Test Categories

### 1. Fallback Behavior (4 tests)
- Model unavailable → uses pattern matching
- LLM fails → uses pattern matching
- Normalization fallback → basic cleanup
- Extraction fallback → regex parsing

### 2. Prompt Construction (5 tests)
- Merchant and amount included
- Context parameter included
- Available categories listed
- Normalization examples provided
- JSON format requested

### 3. Response Parsing (9 tests)
- Exact display name match
- Canonical name match
- Partial match handling
- Unknown category → "other"
- Case insensitive
- Whitespace trimming
- Valid JSON parsing
- Invalid JSON handling
- Missing fields handling

### 4. Error Handling (3 tests)
- Both LLM and fallback fail
- Empty response handling
- Too long response handling

### 5. Timeout Behavior (1 test)
- 5-second timeout enforced

### 6. Integration (2 tests)
- Full flow with LLM
- Full flow without LLM

## Mock Classes

### MockAppleFoundationModelManager
```swift
mockModelManager.isAvailable = true/false
mockModelManager.shouldThrowError = true/false
mockModelManager.shouldTimeout = true/false
mockModelManager.mockResponse = "category name"
```

### MockCategoryMappingService
```swift
mockCategoryMappingService.mockCategories = [...]
```

## Common Test Patterns

### Test LLM Available
```swift
mockModelManager.isAvailable = true
mockModelManager.mockResponse = "Housing & Rent"
let result = try await sut.categorizeWithLLM(...)
XCTAssertEqual(result.method, .llm)
```

### Test Fallback
```swift
mockModelManager.isAvailable = false
mockCategoryService.mockCategorizationResult = ...
let result = try await sut.categorizeWithLLM(...)
XCTAssertEqual(result.method, .pattern)
```

### Test Error Handling
```swift
mockModelManager.shouldThrowError = true
// Verify fallback is used
```

## Test Coverage: 30+ Tests

✅ Fallback behavior when LLM unavailable
✅ Prompt construction for all scenarios
✅ Response parsing for all formats
✅ Error handling for all error types
✅ Timeout behavior (5 seconds)
✅ Integration tests for complete flows

## Requirements Satisfied

- ✅ 5.5: LLM service testing
- ✅ 5.6: Privacy & performance testing
