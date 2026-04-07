import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var dataManager = DataManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            UploadView()
                .tabItem {
                    Label("Upload", systemImage: "plus.circle.fill")
                }
                .tag(1)
            
            FlashcardsView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.stack.fill")
                }
                .tag(2)
            
            QuizView()
                .tabItem {
                    Label("Quiz", systemImage: "questionmark.circle.fill")
                }
                .tag(3)
            
            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(4)
        }
        .environment(dataManager)
    }
}

// MARK: - Home View
struct HomeView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var selectedDocument: Document?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back!")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Ready to study smarter?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundStyle(.tint)
                    }
                    .padding()
                    
                    // Quick Stats
                    HStack(spacing: 12) {
                        QuickStatCard(value: "\(dataManager.documents.count)", label: "Documents", color: .blue)
                        QuickStatCard(value: "\(dataManager.flashcards.count)", label: "Flashcards", color: .purple)
                        QuickStatCard(value: "\(dataManager.progress.currentStreak)", label: "Day Streak", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // Recent Documents
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Documents")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if dataManager.documents.isEmpty {
                            VStack(spacing: 8) {
                                Text("No documents yet")
                                    .foregroundStyle(.secondary)
                                Text("Upload your first study material to get started!")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.quaternary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        } else {
                            ForEach(dataManager.documents.prefix(5)) { document in
                                DocumentRow(document: document)
                                    .onTapGesture {
                                        selectedDocument = document
                                    }
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("cognify")
            .navigationDestination(item: $selectedDocument) { document in
                DocumentDetailView(document: document)
            }
        }
    }
}

struct QuickStatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct DocumentRow: View {
    let document: Document
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForDocumentType(document.type))
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(document.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if document.processedByAI {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private func iconForDocumentType(_ type: DocumentType) -> String {
        switch type {
        case .pdf: return "doc.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        }
    }
}

// MARK: - Upload View
struct UploadView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var showingTextInput = false
    @State private var showingPDFPicker = false
    @State private var isProcessing = false
    @State private var processingStatus = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isProcessing {
                    ProgressView(processingStatus)
                        .padding()
                } else {
                    Spacer()
                    
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                    
                    Text("Upload Study Material")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("PDFs, images, or paste text")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 12) {
                        Button(action: { showingPDFPicker = true }) {
                            Label("Choose PDF", systemImage: "doc.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: { showingCamera = true }) {
                            Label("Take Photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        PhotosPicker(selection: $selectedImages, matching: .images) {
                            Label("Choose Image", systemImage: "photo.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: { showingTextInput = true }) {
                            Label("Paste Text", systemImage: "doc.text.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationTitle("Upload")
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    processImage(image)
                }
            }
            .sheet(isPresented: $showingTextInput) {
                TextInputView { text in
                    processText(text)
                }
            }
            .fileImporter(isPresented: $showingPDFPicker, allowedContentTypes: [.pdf]) { result in
                handlePDFSelection(result)
            }
            .onChange(of: selectedImages) { oldValue, newValue in
                if !newValue.isEmpty {
                    Task {
                        await processSelectedImages()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        Task {
            isProcessing = true
            processingStatus = "Extracting text from image..."
            
            do {
                let extractedText = try await OCRService.shared.extractText(from: image)
                
                // Create document
                let imageData = image.jpegData(compressionQuality: 0.7)
                let document = Document(
                    title: "Scanned Image \(Date().formatted(date: .abbreviated, time: .shortened))",
                    content: extractedText,
                    type: .image,
                    thumbnailData: imageData
                )
                
                dataManager.addDocument(document)
                
                // Process with AI
                await processWithAI(document)
                
                isProcessing = false
                processingStatus = ""
            } catch {
                isProcessing = false
                showError(error.localizedDescription)
            }
        }
    }
    
    private func processSelectedImages() async {
        isProcessing = true
        processingStatus = "Processing images..."
        
        var images: [UIImage] = []
        
        for item in selectedImages {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        
        selectedImages.removeAll()
        
        guard !images.isEmpty else {
            isProcessing = false
            showError("Failed to load images")
            return
        }
        
        do {
            processingStatus = "Extracting text..."
            let extractedText = try await OCRService.shared.extractText(from: images)
            
            let thumbnailData = images.first?.jpegData(compressionQuality: 0.5)
            let document = Document(
                title: "Images \(Date().formatted(date: .abbreviated, time: .shortened))",
                content: extractedText,
                type: .image,
                thumbnailData: thumbnailData
            )
            
            dataManager.addDocument(document)
            
            await processWithAI(document)
            
            isProcessing = false
            processingStatus = ""
        } catch {
            isProcessing = false
            showError(error.localizedDescription)
        }
    }
    
    private func processText(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter some text")
            return
        }
        
        Task {
            isProcessing = true
            processingStatus = "Processing text..."
            
            let document = Document(
                title: "Text Note \(Date().formatted(date: .abbreviated, time: .shortened))",
                content: text,
                type: .text
            )
            
            dataManager.addDocument(document)
            
            await processWithAI(document)
            
            isProcessing = false
            processingStatus = ""
        }
    }
    
    private func handlePDFSelection(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            processPDF(url)
        case .failure(let error):
            showError(error.localizedDescription)
        }
    }
    
    private func processPDF(_ url: URL) {
        Task {
            isProcessing = true
            processingStatus = "Processing PDF..."
            
            // In production, you'd extract text from PDF using PDFKit
            // For now, placeholder
            let document = Document(
                title: url.lastPathComponent,
                content: "PDF content would be extracted here",
                type: .pdf
            )
            
            dataManager.addDocument(document)
            
            await processWithAI(document)
            
            isProcessing = false
            processingStatus = ""
        }
    }
    
    private func processWithAI(_ document: Document) async {
        processingStatus = "Generating flashcards and quiz..."
        
        do {
            // Generate flashcards - use fallback for demo mode
            let flashcardResponses: [FlashcardResponse]
            if NetworkService.USE_MOCK_DATA {
                flashcardResponses = try await MockDataService.shared.generateFlashcards(from: document.content, count: 10)
            } else {
                flashcardResponses = try await NetworkService.shared.generateFlashcards(from: document.content, count: 10)
            }
            
            let flashcards = flashcardResponses.map { response in
                Flashcard(
                    question: response.question,
                    answer: response.answer,
                    documentId: document.id,
                    difficulty: parseDifficulty(response.difficulty)
                )
            }
            dataManager.addFlashcards(flashcards)
            
            // Generate quiz - use fallback for demo mode
            let quizResponses: [QuizQuestionResponse]
            if NetworkService.USE_MOCK_DATA {
                quizResponses = try await MockDataService.shared.generateQuiz(from: document.content, questionCount: 5)
            } else {
                quizResponses = try await NetworkService.shared.generateQuiz(from: document.content, questionCount: 5)
            }
            
            let quizQuestions = quizResponses.map { response in
                QuizQuestion(
                    question: response.question,
                    options: response.options,
                    correctAnswer: response.correctAnswer,
                    explanation: response.explanation
                )
            }
            
            let quiz = Quiz(
                title: "Quiz: \(document.title)",
                documentId: document.id,
                questions: quizQuestions
            )
            dataManager.addQuiz(quiz)
            
            // Mark document as processed
            if let index = dataManager.documents.firstIndex(where: { $0.id == document.id }) {
                dataManager.documents[index].processedByAI = true
            }
            
        } catch {
            // AI processing failed, but document is still saved
            print("AI processing failed: \(error.localizedDescription)")
            // Could show a non-blocking notification here
        }
    }
    
    private func parseDifficulty(_ difficultyString: String?) -> Difficulty {
        guard let difficultyString = difficultyString?.lowercased() else { return .medium }
        switch difficultyString {
        case "easy": return .easy
        case "hard": return .hard
        default: return .medium
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Flashcards View
struct FlashcardsView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var selectedDocument: Document?
    @State private var showingStudyMode = false
    
    var body: some View {
        NavigationStack {
            Group {
                if dataManager.flashcards.isEmpty {
                    ContentUnavailableView(
                        "No flashcards yet",
                        systemImage: "rectangle.stack",
                        description: Text("Upload materials to generate flashcards")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Study Due Section
                            let dueCards = dataManager.getFlashcardsDueForReview()
                            if !dueCards.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Due for Review")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(dueCards.count) cards")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Button(action: { showingStudyMode = true }) {
                                        HStack {
                                            Image(systemName: "brain.head.profile")
                                            Text("Start Review Session")
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                        }
                                        .padding()
                                        .background(.blue.gradient)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                .padding()
                            }
                            
                            // Flashcards by Document
                            ForEach(dataManager.documents) { document in
                                let flashcards = dataManager.getFlashcards(for: document.id)
                                if !flashcards.isEmpty {
                                    DocumentFlashcardSection(document: document, flashcards: flashcards)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Flashcards")
            .sheet(isPresented: $showingStudyMode) {
                FlashcardStudyView(flashcards: dataManager.getFlashcardsDueForReview())
            }
        }
    }
}

struct DocumentFlashcardSection: View {
    let document: Document
    let flashcards: [Flashcard]
    @State private var showingAllCards = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(document.title)
                    .font(.headline)
                Spacer()
                Text("\(flashcards.count) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: { showingAllCards = true }) {
                HStack {
                    Text("Study All")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding()
                .background(.purple.opacity(0.1))
                .foregroundStyle(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .sheet(isPresented: $showingAllCards) {
            FlashcardStudyView(flashcards: flashcards)
        }
    }
}

// MARK: - Quiz View
struct QuizView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var selectedQuiz: Quiz?
    
    var body: some View {
        NavigationStack {
            Group {
                if dataManager.quizzes.isEmpty {
                    ContentUnavailableView(
                        "No quizzes available",
                        systemImage: "questionmark.circle",
                        description: Text("Generate quizzes from your study materials")
                    )
                } else {
                    List {
                        ForEach(dataManager.quizzes) { quiz in
                            QuizRow(quiz: quiz)
                                .onTapGesture {
                                    selectedQuiz = quiz
                                }
                        }
                    }
                }
            }
            .navigationTitle("Quiz")
            .sheet(item: $selectedQuiz) { quiz in
                QuizTakingView(quiz: quiz)
            }
        }
    }
}

struct QuizRow: View {
    let quiz: Quiz
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(quiz.title)
                    .font(.headline)
                Spacer()
                if quiz.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            HStack {
                Label("\(quiz.questions.count) questions", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if let score = quiz.score {
                    Text("\(Int(score))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(scoreColor(score).opacity(0.2))
                        .foregroundStyle(scoreColor(score))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
}

// MARK: - Progress Dashboard View
struct ProgressDashboardView: View {
    @Environment(DataManager.self) private var dataManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Study Streak
                    VStack(spacing: 8) {
                        Text("ðŸ”¥")
                            .font(.system(size: 50))
                        Text("\(dataManager.progress.currentStreak) Day Streak")
                            .font(.title2)
                            .fontWeight(.semibold)
                        if dataManager.progress.currentStreak > 0 {
                            Text("Keep it up! Your longest streak: \(dataManager.progress.longestStreak) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Start learning to build your streak!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            value: "\(dataManager.documents.count)",
                            label: "Documents",
                            icon: "doc.fill",
                            color: .blue
                        )
                        StatCard(
                            value: "\(dataManager.flashcards.count)",
                            label: "Flashcards",
                            icon: "rectangle.stack.fill",
                            color: .purple
                        )
                        StatCard(
                            value: "\(dataManager.quizzes.count)",
                            label: "Quizzes",
                            icon: "pencil.circle.fill",
                            color: .green
                        )
                        StatCard(
                            value: String(format: "%.0f%%", dataManager.progress.overallAccuracy),
                            label: "Accuracy",
                            icon: "target",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Weak Topics
                    if !dataManager.weakTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Areas to Improve")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(dataManager.weakTopics.prefix(5)) { topic in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(topic.topic)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text("\(topic.incorrectCount) mistakes")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .onAppear {
                dataManager.analyzeWeakTopics()
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}