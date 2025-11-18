import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct StatementUploadView: View {
    // State Management: @StateObject is used because this View owns the ViewModel lifecycle.
    // The ViewModel is injected via the initializer from the DI container, following the
    // dependency injection pattern established in the architecture refactoring.
    @StateObject private var viewModel: StatementUploadViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.diContainer) private var container
    @State private var showSuccess = false
    
    init(viewModel: StatementUploadViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    if !viewModel.parsedTransactions.isEmpty && !viewModel.isProcessing {
                        TransactionReviewView(
                            transactions: viewModel.parsedTransactions,
                            onConfirm: {
                                viewModel.confirmTransactions()
                                showSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    dismiss()
                                }
                            },
                            onCancel: viewModel.resetUpload,
                            viewModel: createTransactionReviewViewModel()
                        )
                    } else {
                        uploadOptionsView
                    }
                }
                .navigationTitle("Upload Statement")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                
                // Processing overlay
                if viewModel.isProcessing {
                    ProcessingOverlay(
                        message: viewModel.processingStatus,
                        progress: viewModel.progress,
                        onCancel: viewModel.cancelProcessing
                    )
                }
                
                // Success overlay
                if showSuccess {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        CheckmarkAnimation()
                        Text("Statement uploaded successfully!")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(40)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                }
            }
            .errorAlert(error: $viewModel.error, primaryAction: { _ in
                viewModel.resetUpload()
            })
        }
    }
    
    private var uploadOptionsView: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Upload Bank Statement")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select a PDF or image file, or take a photo of your statement")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Upload options
            VStack(spacing: 16) {
                // Document picker button
                Button(action: viewModel.showDocumentPicker) {
                    HStack {
                        Image(systemName: "folder")
                            .font(.title2)
                        Text("Choose File")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Camera button
                Button(action: viewModel.showCamera) {
                    HStack {
                        Image(systemName: "camera")
                            .font(.title2)
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Photo library button
                Button(action: viewModel.showPhotoLibrary) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                        Text("Photo Library")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            // Supported formats info
            VStack(spacing: 8) {
                Text("Supported Formats")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("PDF, JPG, PNG, HEIC")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $viewModel.showingDocumentPicker) {
            DocumentPicker(
                allowedTypes: [.pdf, .jpeg, .png, .heic],
                onDocumentSelected: viewModel.processDocument
            )
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            CameraView(onImageCaptured: viewModel.processImage)
        }
        .sheet(isPresented: $viewModel.showingPhotoLibrary) {
            PhotoLibraryPicker(onImageSelected: viewModel.processImage)
        }
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    let progress: Float
    let status: String
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Processing animation
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Processing Statement")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(status)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Cancel button
            Button("Cancel", action: onCancel)
                .font(.headline)
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let allowedTypes: [UTType]
    let onDocumentSelected: (Data, String, UTType) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                let contentType = UTType(filenameExtension: url.pathExtension) ?? .data
                
                parent.onDocumentSelected(data, filename, contentType)
            } catch {
                print("Error reading document: \(error)")
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Library Picker

struct PhotoLibraryPicker: View {
    let onImageSelected: (UIImage) -> Void
    @State private var selectedItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                VStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("Select Photo")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Photo Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedItem) { _, item in
                Task {
                    if let item = item,
                       let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        onImageSelected(image)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let ocrService = VisionOCRService()
    let parserService = SmartTransactionParser()
    let transactionRepo = CoreDataTransactionRepository(context: context)
    let accountRepo = CoreDataAccountRepository(context: context)
    
    let modelManager = AppleFoundationModelManager()
    let categoryService = CategoryService(context: context)
    let categoryMappingService = CategoryMappingService()
    let llmService = AppleLLMCategorizationService(
        modelManager: modelManager,
        fallbackService: categoryService,
        categoryMappingService: categoryMappingService
    )
    
    let viewModel = StatementUploadViewModel(
        ocrService: ocrService,
        parserService: parserService,
        transactionRepository: transactionRepo,
        accountRepository: accountRepo,
        statementRepository: CoreDataStatementRepository(context: context),
        llmService: llmService,
        context: context
    )
    
    StatementUploadView(viewModel: viewModel)
}

// MARK: - Helper Methods Extension

extension StatementUploadView {
    private func createTransactionReviewViewModel() -> TransactionReviewViewModel {
        // Check if TransactionParserService is available in the container
        guard let parserService: TransactionParserService = container.resolveOptional(TransactionParserService.self) else {
            // Fallback - create with default parser service
            let mockParserService = SmartTransactionParser()
            return TransactionReviewViewModel(parserService: mockParserService)
        }
        
        return TransactionReviewViewModel(parserService: parserService)
    }
}