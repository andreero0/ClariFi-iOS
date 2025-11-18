# Error Handling & Validation - Quick Reference

## Overview
This guide provides quick reference for the error handling and validation system implemented in Phase 6.

## Error Enums

### CategoryMappingError
**Location:** `Models/CategoryMappingError.swift`

```swift
enum CategoryMappingError: Error, LocalizedError {
    case categoryNotFound(templateName: String)
    case ambiguousMapping(templateName: String, matches: [String])
    case invalidCanonicalName(name: String)
    case mappingServiceUnavailable
}
```

**Usage:**
```swift
// Throw error
throw CategoryMappingError.categoryNotFound(templateName: "Unknown Category")

// Handle error
do {
    let category = try getCategory(name)
} catch let error as CategoryMappingError {
    print(error.errorDescription)
    print(error.recoverySuggestion)
}
```

### OnboardingError
**Location:** `Models/OnboardingError.swift`

```swift
enum OnboardingError: Error, LocalizedError {
    case accountCreationFailed(reason: String?)
    case biometricSetupFailed(reason: String?)
    case invalidConfiguration
    case invalidAccountData(field: String)
    case duplicateAccountName(name: String)
    case stepValidationFailed(step: String)
    case persistenceFailed
}
```

**Usage:**
```swift
// Throw error
throw OnboardingError.duplicateAccountName(name: "Checking")

// Handle error
do {
    try createAccount(data)
} catch let error as OnboardingError {
    showAlert(error.errorDescription, message: error.recoverySuggestion)
}
```

### LLMError
**Location:** `Services/LLM/AppleFoundationModelManager.swift`

```swift
enum LLMError: Error, LocalizedError {
    case modelNotAvailable
    case notImplemented
    case invalidResponse
    case timeout
    case queryFailed
    case invalidPrompt
}
```

**Usage:**
```swift
// Automatic fallback in AppleLLMCategorizationService
do {
    let result = try await modelManager.query(prompt: prompt)
} catch let error as LLMError {
    // Automatically falls back to pattern matching
    return try await fallbackToCategoryService(merchant: merchant, amount: amount)
}
```

## Validation Patterns

### Real-Time Field Validation

**Pattern:**
```swift
@State private var fieldValue: String = ""
@State private var fieldError: String?
@State private var hasAttemptedSave: Bool = false

// In body
TextField("Field", text: $fieldValue)
    .onChange(of: fieldValue) { _ in
        if hasAttemptedSave {
            validateField()
        }
    }
    .overlay(
        RoundedRectangle(cornerRadius: 8)
            .stroke(fieldError != nil ? Color.red : Color.clear, lineWidth: 1)
    )

if let error = fieldError {
    Text(error)
        .font(.caption)
        .foregroundColor(.red)
}

// Validation method
private func validateField() {
    if fieldValue.isEmpty {
        fieldError = "Field is required"
    } else {
        fieldError = nil
    }
}

// On save
private func save() {
    hasAttemptedSave = true
    validateField()
    
    guard fieldError == nil else {
        return
    }
    
    // Proceed with save
}
```

### Form-Level Validation

**Pattern:**
```swift
func validateForm() -> Bool {
    var isValid = true
    
    // Reset errors
    merchantError = nil
    amountError = nil
    categoryError = nil
    
    // Validate each field
    if merchant.isEmpty {
        merchantError = "Merchant is required"
        isValid = false
    }
    
    if amount.isEmpty {
        amountError = "Amount is required"
        isValid = false
    }
    
    return isValid
}

// Usage
func save() {
    guard validateForm() else {
        return
    }
    
    // Proceed with save
}
```

### Debounced Validation

**Pattern:**
```swift
import Combine

private var cancellables = Set<AnyCancellable>()

private func setupObservers() {
    $fieldValue
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .sink { [weak self] value in
            guard let self = self else { return }
            if !value.isEmpty && self.fieldError != nil {
                self.validateField()
            }
        }
        .store(in: &cancellables)
}
```

## Error Recovery Patterns

### LLM Fallback Pattern

**Pattern:**
```swift
func categorizeWithLLM(merchant: String, amount: Decimal) async throws -> Result {
    // Check if LLM is available
    guard modelManager.isAvailable else {
        print("ℹ️ LLM not available, using fallback")
        return try await fallbackToCategoryService(merchant: merchant, amount: amount)
    }
    
    do {
        // Try LLM
        let response = try await modelManager.query(prompt: prompt)
        return parseResponse(response)
        
    } catch let error as LLMError {
        // Log user-friendly error
        print("⚠️ LLM failed: \(error.errorDescription ?? "Unknown")")
        print("   Recovery: \(error.recoverySuggestion ?? "")")
        
        // Automatic fallback
        return try await fallbackToCategoryService(merchant: merchant, amount: amount)
    }
}
```

### Category Mapping Fallback Pattern

**Pattern:**
```swift
// With fallback method
func getCanonicalCategoryWithFallback(from templateName: String) -> CategoryDefinition {
    // Try to find category
    if let category = getCanonicalCategory(from: templateName) {
        return category
    }
    
    // Log failure
    print("⚠️ Category mapping failed for: '\(templateName)'")
    print("   Defaulting to 'Other' category")
    
    // Return fallback
    return canonicalNameLookup["other"] ?? defaultOtherCategory
}

// Safe category validation
func ensureValidCategory(_ categoryName: String) -> String {
    // Check if valid
    if availableCategories.contains(where: { $0.canonicalName == categoryName }) {
        return categoryName
    }
    
    // Try to map
    if let category = categoryMappingService.getCanonicalCategory(from: categoryName) {
        return category.canonicalName
    }
    
    // Log and fallback
    print("⚠️ Invalid category: '\(categoryName)', using 'other'")
    return "other"
}
```

## Common Validation Rules

### Account Name Validation
```swift
func validateAccountName(_ name: String) -> String? {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if trimmed.isEmpty {
        return "Account name cannot be empty"
    }
    
    if trimmed.count < 2 {
        return "Account name must be at least 2 characters"
    }
    
    if trimmed.count > 50 {
        return "Account name cannot exceed 50 characters"
    }
    
    return nil
}
```

### Amount Validation
```swift
func validateAmount(_ amount: String) -> String? {
    let trimmed = amount.trimmingCharacters(in: .whitespaces)
    
    if trimmed.isEmpty {
        return "Amount is required"
    }
    
    guard let decimal = Decimal(string: trimmed) else {
        return "Invalid amount format"
    }
    
    if decimal <= 0 {
        return "Amount must be greater than zero"
    }
    
    return nil
}
```

### Category Validation
```swift
func validateCategory(_ category: String, availableCategories: [CategoryDefinition]) -> String? {
    if category.isEmpty {
        return "Category is required"
    }
    
    let exists = availableCategories.contains { cat in
        cat.canonicalName == category || cat.displayName == category
    }
    
    if !exists {
        return "Invalid category selected"
    }
    
    return nil
}
```

## Error Logging Best Practices

### Structured Logging
```swift
// Good: Structured with context
print("⚠️ LLM categorization failed: \(error.errorDescription ?? "Unknown")")
print("   Merchant: \(merchant)")
print("   Amount: \(amount)")
print("   Reason: \(error.failureReason ?? "")")
print("   Recovery: \(error.recoverySuggestion ?? "")")

// Bad: Unstructured
print("Error: \(error)")
```

### Log Levels
```swift
// ℹ️ Info - Normal operation
print("ℹ️ LLM not available, using fallback")

// ⚠️ Warning - Recoverable error
print("⚠️ Category mapping failed, using 'Other'")

// ❌ Error - Unrecoverable error
print("❌ Failed to save transaction: \(error)")

// ✅ Success - Operation completed
print("✅ Transaction saved successfully")
```

### Performance Tracking
```swift
// Track fallback usage
var llmFailureCount = 0
var fallbackCount = 0

// Log summary
print("ℹ️ Processing Summary:")
print("   - Total: \(total)")
print("   - Failures: \(llmFailureCount)")
print("   - Fallbacks: \(fallbackCount)")
print("   - Success: \(total - llmFailureCount)")
```

## User Feedback Patterns

### Inline Error Messages
```swift
if let error = fieldError {
    HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.red)
        Text(error)
            .font(.caption)
            .foregroundColor(.red)
    }
}
```

### Alert Dialogs
```swift
.alert("Error", isPresented: $showError) {
    Button("OK") {
        showError = false
    }
} message: {
    Text(errorMessage)
}
```

### Toast Messages
```swift
if showSuccessMessage {
    VStack {
        Spacer()
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Saved successfully")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 10)
    }
    .transition(.move(edge: .bottom))
}
```

## Testing Error Handling

### Unit Test Pattern
```swift
func testValidation_EmptyField_ReturnsError() {
    // Given
    let viewModel = TransactionEntryViewModel(...)
    viewModel.merchant = ""
    
    // When
    let isValid = viewModel.validateForm()
    
    // Then
    XCTAssertFalse(isValid)
    XCTAssertNotNil(viewModel.merchantError)
    XCTAssertEqual(viewModel.merchantError, "Merchant is required")
}
```

### Integration Test Pattern
```swift
func testLLMFallback_WhenModelUnavailable_UsesFallback() async throws {
    // Given
    let service = AppleLLMCategorizationService(...)
    
    // When
    let result = try await service.categorizeWithLLM(
        merchant: "Starbucks",
        amount: 5.00,
        context: nil
    )
    
    // Then
    XCTAssertNotNil(result)
    XCTAssertEqual(result.method, .pattern) // Fallback method
}
```

## Quick Checklist

When implementing error handling:
- [ ] Define specific error cases
- [ ] Implement `LocalizedError` protocol
- [ ] Add user-friendly error descriptions
- [ ] Add failure reasons
- [ ] Add recovery suggestions
- [ ] Implement real-time validation
- [ ] Add visual error feedback
- [ ] Preserve user input on errors
- [ ] Log errors with context
- [ ] Implement automatic fallback
- [ ] Test error scenarios
- [ ] Document error handling

## Common Pitfalls

### ❌ Don't
```swift
// Generic error messages
throw NSError(domain: "Error", code: 1, userInfo: nil)

// No user feedback
if error != nil {
    return
}

// Losing user data
func reset() {
    fieldValue = ""
    fieldError = nil
}
```

### ✅ Do
```swift
// Specific error types
throw OnboardingError.duplicateAccountName(name: accountName)

// Clear user feedback
if let error = fieldError {
    Text(error)
        .foregroundColor(.red)
}

// Preserve user data
func reset() {
    // Only reset on successful save
    if error == nil {
        fieldValue = ""
    }
}
```

## Summary

The error handling system provides:
1. **Specific error types** for different failure scenarios
2. **User-friendly messages** instead of technical jargon
3. **Real-time validation** with immediate feedback
4. **Automatic fallback** for recoverable errors
5. **Comprehensive logging** for debugging
6. **Data preservation** during error states

All errors are handled gracefully with clear user feedback and automatic recovery where possible.
