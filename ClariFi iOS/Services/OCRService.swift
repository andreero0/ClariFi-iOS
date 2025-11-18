import Foundation
import Vision
import UIKit
import PDFKit

// MARK: - OCR Service Protocol

protocol OCRService {
    func processDocument(_ data: Data, type: DocumentType) async throws -> OCRResult
    func processImage(_ image: UIImage) async throws -> OCRResult
}

// MARK: - Supporting Types

enum DocumentType {
    case pdf
    case image(ImageFormat)
    
    enum ImageFormat {
        case jpeg
        case png
        case heic
    }
}

struct OCRResult {
    let rawText: String
    let confidence: Float
    let boundingBoxes: [TextBoundingBox]
    let processingTime: TimeInterval
    let preprocessingApplied: [PreprocessingStep]
}

struct TextBoundingBox {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
}

enum PreprocessingStep {
    case deskew
    case denoise
    case contrastAdjustment
    case resolutionEnhancement
}

// MARK: - OCR Errors

enum OCRError: LocalizedError {
    case unsupportedDocumentType
    case processingFailed(String)
    case noTextFound
    case lowConfidence(Float)
    case memoryLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .unsupportedDocumentType:
            return "Document type not supported for OCR processing"
        case .processingFailed(let reason):
            return "OCR processing failed: \(reason)"
        case .noTextFound:
            return "No text could be detected in the document"
        case .lowConfidence(let confidence):
            return "Text recognition confidence too low: \(confidence)"
        case .memoryLimitExceeded:
            return "Document too large for processing"
        }
    }
}