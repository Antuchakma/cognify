import SwiftUI
import UIKit

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
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
                parent.completion(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Text Input View
struct TextInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    let completion: (String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $text)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(minHeight: 200)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Enter Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        completion(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Document Detail View
struct DocumentDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    let document: Document
    @State private var showingDeleteConfirmation = false
    @State private var showingExplanation = false
    @State private var selectedExplanationLevel: ExplanationLevel = .detailed
    @State private var explanation: String?
    @State private var isGeneratingExplanation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Document Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(document.type.rawValue, systemImage: iconForType(document.type))
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(document.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                    Text(document.content)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                // AI Actions
                VStack(spacing: 12) {
                    Button(action: { showingExplanation = true }) {
                        Label("Get AI Explanation", systemImage: "brain")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    let flashcards = dataManager.getFlashcards(for: document.id)
                    NavigationLink(destination: FlashcardStudyView(flashcards: flashcards)) {
                        HStack {
                            Label("Study Flashcards (\(flashcards.count))", systemImage: "rectangle.stack")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.opacity(0.1))
                        .foregroundStyle(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(flashcards.isEmpty)
                    
                    let quizzes = dataManager.getQuizzes(for: document.id)
                    if let quiz = quizzes.first {
                        NavigationLink(destination: QuizTakingView(quiz: quiz)) {
                            HStack {
                                Label("Take Quiz", systemImage: "questionmark.circle")
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal)
                
                // Delete Button
                Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                    Label("Delete Document", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExplanation) {
            ExplanationView(
                document: document,
                selectedLevel: $selectedExplanationLevel
            )
        }
        .alert("Delete Document?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                dataManager.deleteDocument(document)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also delete all associated flashcards and quizzes.")
        }
    }
    
    private func iconForType(_ type: DocumentType) -> String {
        switch type {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        }
    }
}

// MARK: - Explanation View
struct ExplanationView: View {
    @Environment(\.dismiss) private var dismiss
    let document: Document
    @Binding var selectedLevel: ExplanationLevel
    @State private var explanation: String?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Level", selection: $selectedLevel) {
                    Text("Beginner").tag(ExplanationLevel.beginner)
                    Text("Detailed").tag(ExplanationLevel.detailed)
                    Text("Exam-Focused").tag(ExplanationLevel.examFocused)
                }
                .pickerStyle(.segmented)
                .padding()
                .onChange(of: selectedLevel) { oldValue, newValue in
                    generateExplanation()
                }
                
                ScrollView {
                    if isLoading {
                        ProgressView("Generating explanation...")
                            .padding()
                    } else if let explanation = explanation {
                        Text(explanation)
                            .padding()
                            .textSelection(.enabled)
                    } else if let error = errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text(error)
                                .foregroundStyle(.secondary)
                            Button("Try Again") {
                                generateExplanation()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    } else {
                        Text("Tap 'Generate' to get an AI explanation")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle("AI Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate") {
                        generateExplanation()
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if explanation == nil {
                    generateExplanation()
                }
            }
        }
    }
    
    private func generateExplanation() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result: String
                if NetworkService.USE_MOCK_DATA {
                    result = try await MockDataService.shared.generateExplanation(
                        from: document.content,
                        level: selectedLevel
                    )
                } else {
                    result = try await NetworkService.shared.generateExplanation(
                        from: document.content,
                        level: selectedLevel
                    )
                }
                explanation = result
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}