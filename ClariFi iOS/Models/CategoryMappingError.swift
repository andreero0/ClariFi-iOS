import Foundation

/// Errors that can occur during category mapping operations
enum CategoryMappingError: Error, LocalizedError {
    case categoryNotFound(templateName: String)
    case ambiguousMapping(templateName: String, matches: [String])
    case invalidCanonicalName(name: String)
    case mappingServiceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .categoryNotFound(let name):
            return "Category '\(name)' not found"
        case .ambiguousMapping(let name, let matches):
            return "Category '\(name)' matches multiple categories: \(matches.joined(separator: ", "))"
        case .invalidCanonicalName(let name):
            return "Invalid category name: '\(name)'"
        case .mappingServiceUnavailable:
            return "Category mapping service is unavailable"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .categoryNotFound:
            return "The specified category could not be found in the system."
        case .ambiguousMapping:
            return "Multiple categories match the provided name."
        case .invalidCanonicalName:
            return "The category name provided is not valid."
        case .mappingServiceUnavailable:
            return "The category mapping service could not be initialized."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .categoryNotFound:
            return "Please select a category from the available options or use 'Other'."
        case .ambiguousMapping:
            return "Please be more specific or select from the suggested categories."
        case .invalidCanonicalName:
            return "Please select a valid category from the list."
        case .mappingServiceUnavailable:
            return "Please restart the app. If the problem persists, contact support."
        }
    }
}
