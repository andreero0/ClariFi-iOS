//
//  OCRServiceTests.swift
//  ClariFi iOS Tests
//
//  Created by aEro on 2025-10-10.
//

import Testing
import UIKit
import Vision
@testable import ClariFi_iOS

struct OCRServiceTests {
    
    let ocrService: VisionOCRService
    
    init() throws {
        ocrService = VisionOCRService()
    }
    
    
    // MARK: - Helper Methods
    
    private func createTestImage(with text: String, size: CGSize = CGSize(width: 400, height: 300)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Black text
            UIColor.black.setFill()
            let font = UIFont.systemFont(ofSize: 16, weight: .medium)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func createTestPDFData(with text: String) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "ClariFi Test",
            kCGPDFContextAuthor: "Test Suite"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let font = UIFont.systemFont(ofSize: 12)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: pageRect.height - 100)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - Image Processing Tests
    
    func testProcessImage_SimpleText() async throws {
        // Given
        let testText = "Hello World"
        let testImage = createTestImage(with: testText)
        
        // When
        let result = try await ocrService.processImage(testImage)
        
        // Then
        #expect(result.rawText.isEmpty == false)
        #expect(result.rawText.contains("Hello" == true))
        #expect(result.confidence > 0.5 == true)
        #expect(result.processingTime > 0 == true)
        #expect(result.boundingBoxes.isEmpty == false)
    }
    
    func testProcessImage_TransactionText() async throws {
        // Given
        let transactionText = """
        01/15/2024 STARBUCKS STORE #1234 $4.50
        01/16/2024 SHELL GAS STATION $35.00
        01/17/2024 GROCERY MART $67.89
        """
        let testImage = createTestImage(with: transactionText, size: CGSize(width: 600, height: 400))
        
        // When
        let result = try await ocrService.processImage(testImage)
        
        // Then
        #expect(result.rawText.isEmpty == false)
        #expect(result.rawText.contains("STARBUCKS" == true))
        #expect(result.rawText.contains("4.50" == true))
        #expect(result.confidence > 0.6 == true)
        #expect(result.boundingBoxes.count > 0)
        
        // Check that bounding boxes have reasonable confidence
        let highConfidenceBoxes = result.boundingBoxes.filter { $0.confidence > 0.7 }
        #expect(highConfidenceBoxes.count > 0)
    }
    
    func testProcessImage_LowQualityImage() async throws {
        // Given - Create a very small, low quality image
        let testText = "Hard to read text"
        let lowQualityImage = createTestImage(with: testText, size: CGSize(width: 50, height: 30))
        
        // When & Then
        do {
            let result = try await ocrService.processImage(lowQualityImage)
            // If it succeeds, confidence should be lower
            #expect(result.confidence < 0.8)
        } catch OCRError.lowConfidence(let confidence) {
            // This is expected for very low quality images
            #expect(confidence < 0.5)
        } catch OCRError.noTextFound {
            // This is also acceptable for very poor quality images
            #expect(true == true)
        }
    }
    
    func testProcessImage_EmptyImage() async throws {
        // Given - Create an image with no text
        let emptyImage = createTestImage(with: "", size: CGSize(width: 200, height: 200))
        
        // When & Then
        do {
            _ = try await ocrService.processImage(emptyImage)
            Issue.record("Should have thrown an error for empty image")
        } catch OCRError.noTextFound {
            // Expected error
            #expect(true == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - PDF Processing Tests
    
    func testProcessDocument_PDFWithText() async throws {
        // Given
        let pdfText = """
        BANK STATEMENT
        Account: 1234-5678-9012
        
        01/15/2024 AMAZON.COM $29.99
        01/16/2024 COFFEE SHOP $5.25
        01/17/2024 GAS STATION $42.00
        
        Total: $77.24
        """
        let pdfData = createTestPDFData(with: pdfText)
        
        // When
        let result = try await ocrService.processDocument(pdfData, type: .pdf)
        
        // Then
        #expect(result.rawText.isEmpty == false)
        #expect(result.rawText.contains("AMAZON" == true))
        #expect(result.rawText.contains("29.99" == true))
        #expect(result.confidence > 0.5 == true)
        #expect(result.processingTime > 0 == true)
    }
    
    func testProcessDocument_ImageData() async throws {
        // Given
        let testText = "01/15/2024 TEST MERCHANT $25.00"
        let testImage = createTestImage(with: testText)
        guard let imageData = testImage.pngData() else {
            Issue.record("Could not create image data")
            return
        }
        
        // When
        let result = try await ocrService.processDocument(imageData, type: .image(.png))
        
        // Then
        #expect(result.rawText.isEmpty == false)
        #expect(result.rawText.contains("TEST MERCHANT" == true))
        #expect(result.confidence > 0.5 == true)
    }
    
    func testProcessDocument_InvalidPDFData() async throws {
        // Given
        let invalidData = "Not a PDF".data(using: .utf8)!
        
        // When & Then
        do {
            _ = try await ocrService.processDocument(invalidData, type: .pdf)
            Issue.record("Should have thrown an error for invalid PDF data")
        } catch OCRError.processingFailed {
            // Expected error
            #expect(true == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    func testProcessDocument_InvalidImageData() async throws {
        // Given
        let invalidData = "Not an image".data(using: .utf8)!
        
        // When & Then
        do {
            _ = try await ocrService.processDocument(invalidData, type: .image(.png))
            Issue.record("Should have thrown an error for invalid image data")
        } catch OCRError.processingFailed {
            // Expected error
            #expect(true == true)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Confidence Scoring Tests
    
    func testConfidenceScoring_HighQualityText() async throws {
        // Given - Clear, well-formatted text
        let clearText = """
        TRANSACTION DETAILS
        Date: 01/15/2024
        Merchant: STARBUCKS STORE #1234
        Amount: $4.50
        """
        let highQualityImage = createTestImage(with: clearText, size: CGSize(width: 500, height: 300))
        
        // When
        let result = try await ocrService.processImage(highQualityImage)
        
        // Then
        #expect(result.confidence > 0.8)
        
        // Check individual bounding box confidences
        let highConfidenceBoxes = result.boundingBoxes.filter { $0.confidence > 0.8 }
        #expect(highConfidenceBoxes.count > 0)
    }
    
    func testConfidenceScoring_MediumQualityText() async throws {
        // Given - Smaller text that might be harder to read
        let mediumText = "01/15/24 Store $10.00"
        let mediumQualityImage = createTestImage(with: mediumText, size: CGSize(width: 200, height: 100))
        
        // When
        let result = try await ocrService.processImage(mediumQualityImage)
        
        // Then
        #expect(result.confidence > 0.5)
        #expect(result.confidence < 0.95)
    }
    
    // MARK: - Preprocessing Tests
    
    func testPreprocessingSteps_Applied() async throws {
        // Given
        let testText = "01/15/2024 TEST STORE $25.99"
        let testImage = createTestImage(with: testText)
        
        // When
        let result = try await ocrService.processImage(testImage)
        
        // Then
        #expect(result.preprocessingApplied.isEmpty == false)
        
        // Check that common preprocessing steps are applied
        let stepTypes = result.preprocessingApplied
        #expect(stepTypes.contains(.contrastAdjustment == true) || stepTypes.contains(.denoise))
    }
    
    // MARK: - Performance Tests
    
    func testProcessingTime_ReasonableDuration() async throws {
        // Given
        let testText = """
        01/15/2024 MERCHANT ONE $25.00
        01/16/2024 MERCHANT TWO $35.50
        01/17/2024 MERCHANT THREE $45.75
        """
        let testImage = createTestImage(with: testText, size: CGSize(width: 400, height: 300))
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await ocrService.processImage(testImage)
        let actualDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        #expect(result.processingTime > 0 == true)
        #expect(result.processingTime < 10.0) // Should complete within 10 seconds
        #expect(abs(result.processingTime - actualDuration) < 1.0) // Reported time should be accurate
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_OCRErrors() {
        // Test error descriptions
        let errors: [OCRError] = [
            .unsupportedDocumentType,
            .processingFailed("Test reason"),
            .noTextFound,
            .lowConfidence(0.3),
            .memoryLimitExceeded
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(error.errorDescription!.isEmpty == false)
        }
    }
    
    // MARK: - Bounding Box Tests
    
    func testBoundingBoxes_ValidCoordinates() async throws {
        // Given
        let testText = "STORE NAME $25.00"
        let testImage = createTestImage(with: testText)
        
        // When
        let result = try await ocrService.processImage(testImage)
        
        // Then
        #expect(result.boundingBoxes.isEmpty == false)
        
        for boundingBox in result.boundingBoxes {
            // Check that bounding box coordinates are valid (normalized 0-1)
            #expect(boundingBox.boundingBox.minX >= 0.0)
            #expect(boundingBox.boundingBox.maxX <= 1.0)
            #expect(boundingBox.boundingBox.minY >= 0.0)
            #expect(boundingBox.boundingBox.maxY <= 1.0)
            
            // Check that text is not empty
            #expect(boundingBox.text.isEmpty == false)
            
            // Check that confidence is reasonable
            #expect(boundingBox.confidence > 0.0)
            #expect(boundingBox.confidence <= 1.0)
        }
    }
}