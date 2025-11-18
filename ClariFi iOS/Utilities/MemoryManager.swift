//
//  MemoryManager.swift
//  ClariFi iOS
//
//  Memory management utilities to prevent image creation failures and memory issues
//

import Foundation
import UIKit
import SwiftUI

/// Memory management utility to prevent image creation failures
class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published var memoryWarningLevel: MemoryWarningLevel = .normal
    @Published var isLowMemory: Bool = false
    
    private var memoryWarningObserver: NSObjectProtocol?
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Memory Warning Handling
    
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        isLowMemory = true
        memoryWarningLevel = .critical
        
        // Clear caches and temporary data
        clearImageCaches()
        clearTemporaryData()
        
        // Notify other parts of the app
        NotificationCenter.default.post(name: .memoryWarningReceived, object: nil)
    }
    
    // MARK: - Memory Management
    
    func clearImageCaches() {
        // Clear any image caches
        URLCache.shared.removeAllCachedResponses()
        
        // Clear Core Data context if needed
        if isLowMemory {
            // Force save and reset context to free memory
            let context = PersistenceController.shared.container.viewContext
            if context.hasChanges {
                try? context.save()
            }
        }
    }
    
    func clearTemporaryData() {
        // Clear temporary files
        let tempDir = FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: tempDir)
        
        // Clear user defaults cache
        UserDefaults.standard.synchronize()
    }
    
    func resetMemoryState() {
        isLowMemory = false
        memoryWarningLevel = .normal
    }
    
    // MARK: - Memory Monitoring
    
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    func getMemoryUsagePercentage() -> Double {
        let currentUsage = getCurrentMemoryUsage()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        return Double(currentUsage) / Double(totalMemory)
    }
}

// MARK: - Memory Warning Level

enum MemoryWarningLevel {
    case normal
    case warning
    case critical
    
    var shouldReduceImageQuality: Bool {
        switch self {
        case .normal: return false
        case .warning: return true
        case .critical: return true
        }
    }
    
    var maxImageSize: CGSize {
        switch self {
        case .normal: return CGSize(width: 1024, height: 1024)
        case .warning: return CGSize(width: 512, height: 512)
        case .critical: return CGSize(width: 256, height: 256)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let memoryWarningReceived = Notification.Name("memoryWarningReceived")
}

// MARK: - Safe Image Loading

struct SafeImageLoader: View {
    let url: URL?
    let placeholder: String
    let maxSize: CGSize?
    
    @StateObject private var memoryManager = MemoryManager.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var hasError = false
    
    init(url: URL?, placeholder: String = "photo", maxSize: CGSize? = nil) {
        self.url = url
        self.placeholder = placeholder
        self.maxSize = maxSize
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if hasError {
                Image(systemName: placeholder)
                    .foregroundColor(.secondary)
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .onAppear {
            loadImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .memoryWarningReceived)) { _ in
            // Clear image on memory warning
            image = nil
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        isLoading = true
        hasError = false
        
        // Determine appropriate image size based on memory state
        let targetSize = maxSize ?? memoryManager.memoryWarningLevel.maxImageSize
        
        Task {
            do {
                let loadedImage = try await loadImageFromURL(url, targetSize: targetSize)
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadImageFromURL(_ url: URL, targetSize: CGSize) async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw ImageLoadingError.invalidData
        }
        
        // Resize image if needed to save memory
        if image.size.width > targetSize.width || image.size.height > targetSize.height {
            return try resizeImage(image, to: targetSize)
        }
        
        return image
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Image Loading Error

enum ImageLoadingError: LocalizedError {
    case invalidData
    case networkError(Error)
    case memoryError
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid image data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .memoryError:
            return "Insufficient memory to load image"
        }
    }
}
