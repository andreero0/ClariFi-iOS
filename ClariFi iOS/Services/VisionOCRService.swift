import Foundation
@preconcurrency import Vision
import UIKit
import PDFKit
import CoreImage

// MARK: - Vision OCR Service Implementation

class VisionOCRService: OCRService {
    
    private let minimumConfidence: Float = 0.5
    private let maxImageSize: CGSize = CGSize(width: 4096, height: 4096)
    
    // MARK: - Public Methods
    
    func processDocument(_ data: Data, type: DocumentType) async throws -> OCRResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        switch type {
        case .pdf:
            return try await processPDF(data, startTime: startTime)
        case .image:
            guard let image = UIImage(data: data) else {
                throw OCRError.processingFailed("Could not create image from data")
            }
            return try await processImage(image, startTime: startTime)
        }
    }
    
    func processImage(_ image: UIImage) async throws -> OCRResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        return try await processImage(image, startTime: startTime)
    }
    
    // MARK: - Private Methods
    
    private func processPDF(_ data: Data, startTime: CFAbsoluteTime) async throws -> OCRResult {
        guard let pdfDocument = PDFDocument(data: data) else {
            throw OCRError.processingFailed("Could not create PDF document from data")
        }
        
        var allText = ""
        var allBoundingBoxes: [TextBoundingBox] = []
        var totalConfidence: Float = 0
        var pageCount = 0
        var allPreprocessingSteps: Set<PreprocessingStep> = []
        
        // Process each page of the PDF
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            // Convert PDF page to image
            let pageRect = page.bounds(for: .mediaBox)
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            
            let pageImage = renderer.image { context in
                UIColor.white.set()
                context.fill(pageRect)
                
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)
                
                page.draw(with: .mediaBox, to: context.cgContext)
            }
            
            // Process the page image
            let pageResult = try await processImage(pageImage, startTime: startTime)
            
            allText += pageResult.rawText + "\n"
            allBoundingBoxes.append(contentsOf: pageResult.boundingBoxes)
            totalConfidence += pageResult.confidence
            pageCount += 1
            allPreprocessingSteps.formUnion(pageResult.preprocessingApplied)
        }
        
        let averageConfidence = pageCount > 0 ? totalConfidence / Float(pageCount) : 0
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return OCRResult(
            rawText: allText.trimmingCharacters(in: .whitespacesAndNewlines),
            confidence: averageConfidence,
            boundingBoxes: allBoundingBoxes,
            processingTime: processingTime,
            preprocessingApplied: Array(allPreprocessingSteps)
        )
    }
    
    private func processImage(_ image: UIImage, startTime: CFAbsoluteTime) async throws -> OCRResult {
        // Preprocess the image
        let (processedImage, preprocessingSteps) = try preprocessImage(image)
        
        // Convert to CGImage
        guard let cgImage = processedImage.cgImage else {
            throw OCRError.processingFailed("Could not get CGImage from processed image")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create Vision request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.processingFailed(error.localizedDescription))
                    return
                }
                
                do {
                    let result = try self.processVisionResults(
                        request.results as? [VNRecognizedTextObservation] ?? [],
                        startTime: startTime,
                        preprocessingSteps: preprocessingSteps
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Configure request for better accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            
            // Perform the request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.processingFailed(error.localizedDescription))
                }
            }
        }
    }
    
    private func preprocessImage(_ image: UIImage) throws -> (UIImage, [PreprocessingStep]) {
        var processedImage = image
        var appliedSteps: [PreprocessingStep] = []
        
        // Resize if too large
        if image.size.width > maxImageSize.width || image.size.height > maxImageSize.height {
            processedImage = try resizeImage(processedImage, to: maxImageSize)
        }
        
        guard let ciImage = CIImage(image: processedImage) else {
            throw OCRError.processingFailed("Could not create CIImage for preprocessing")
        }
        
        var filteredImage = ciImage
        
        // Apply contrast adjustment
        if shouldApplyContrastAdjustment(to: ciImage) {
            let contrastFilter = CIFilter(name: "CIColorControls")!
            contrastFilter.setValue(filteredImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.2, forKey: kCIInputContrastKey)
            contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey)
            
            if let output = contrastFilter.outputImage {
                filteredImage = output
                appliedSteps.append(.contrastAdjustment)
            }
        }
        
        // Apply denoising
        if shouldApplyDenoising(to: filteredImage) {
            let noiseFilter = CIFilter(name: "CINoiseReduction")!
            noiseFilter.setValue(filteredImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
            noiseFilter.setValue(0.40, forKey: "inputSharpness")
            
            if let output = noiseFilter.outputImage {
                filteredImage = output
                appliedSteps.append(.denoise)
            }
        }
        
        // Convert back to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            throw OCRError.processingFailed("Could not create CGImage from filtered image")
        }
        
        processedImage = UIImage(cgImage: cgImage)
        
        return (processedImage, appliedSteps)
    }
    
    private func resizeImage(_ image: UIImage, to maxSize: CGSize) throws -> UIImage {
        let size = image.size
        let widthRatio = maxSize.width / size.width
        let heightRatio = maxSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func shouldApplyContrastAdjustment(to image: CIImage) -> Bool {
        // Simple heuristic: apply contrast adjustment if image appears low contrast
        // In a real implementation, you might analyze histogram
        return true
    }
    
    private func shouldApplyDenoising(to image: CIImage) -> Bool {
        // Simple heuristic: apply denoising for most images
        // In a real implementation, you might detect noise levels
        return true
    }
    
    private func processVisionResults(
        _ observations: [VNRecognizedTextObservation],
        startTime: CFAbsoluteTime,
        preprocessingSteps: [PreprocessingStep]
    ) throws -> OCRResult {
        var allText = ""
        var boundingBoxes: [TextBoundingBox] = []
        var totalConfidence: Float = 0
        var observationCount = 0
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let confidence = topCandidate.confidence
            
            // Skip very low confidence text
            if confidence < minimumConfidence {
                continue
            }
            
            let text = topCandidate.string
            allText += text + " "
            
            // Convert normalized coordinates to bounding box
            let boundingBox = TextBoundingBox(
                text: text,
                confidence: confidence,
                boundingBox: observation.boundingBox
            )
            boundingBoxes.append(boundingBox)
            
            totalConfidence += confidence
            observationCount += 1
        }
        
        if observationCount == 0 {
            throw OCRError.noTextFound
        }
        
        let averageConfidence = totalConfidence / Float(observationCount)
        
        if averageConfidence < minimumConfidence {
            throw OCRError.lowConfidence(averageConfidence)
        }
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return OCRResult(
            rawText: allText.trimmingCharacters(in: .whitespacesAndNewlines),
            confidence: averageConfidence,
            boundingBoxes: boundingBoxes,
            processingTime: processingTime,
            preprocessingApplied: preprocessingSteps
        )
    }
}