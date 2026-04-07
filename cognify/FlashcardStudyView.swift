import SwiftUI

struct FlashcardStudyView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    let flashcards: [Flashcard]
    
    @State private var currentIndex = 0
    @State private var isShowingAnswer = false
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var correctCount = 0
    @State private var incorrectCount = 0
    @State private var isComplete = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if flashcards.isEmpty {
                    ContentUnavailableView(
                        "No Flashcards",
                        systemImage: "rectangle.stack",
                        description: Text("Add some flashcards to study")
                    )
                } else if isComplete {
                    // Completion View
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                        
                        Text("Study Session Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Text("Correct")
                            }
                            
                            HStack {
                                Label("\(incorrectCount)", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Spacer()
                                Text("Incorrect")
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Accuracy")
                                Spacer()
                                Text("\(Int(Double(correctCount) / Double(correctCount + incorrectCount) * 100))%")
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                } else {
                    // Progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("Card \(currentIndex + 1) of \(flashcards.count)")
                                .font(.headline)
                            Spacer()
                            HStack(spacing: 16) {
                                Label("\(correctCount)", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Label("\(incorrectCount)", systemImage: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .font(.caption)
                        }
                        
                        ProgressView(value: Double(currentIndex), total: Double(flashcards.count))
                    }
                    .padding()
                    
                    // Flashcard
                    ZStack {
                        ForEach(Array(flashcards.enumerated()), id: \.element.id) { index, flashcard in
                            if index == currentIndex {
                                FlashcardView(
                                    flashcard: flashcard,
                                    isShowingAnswer: isShowingAnswer
                                )
                                .offset(offset)
                                .rotationEffect(.degrees(rotation))
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            offset = gesture.translation
                                            rotation = Double(gesture.translation.width / 20)
                                        }
                                        .onEnded { gesture in
                                            let swipeThreshold: CGFloat = 100
                                            
                                            if gesture.translation.width > swipeThreshold {
                                                // Swiped right - Correct
                                                handleAnswer(correct: true)
                                            } else if gesture.translation.width < -swipeThreshold {
                                                // Swiped left - Incorrect
                                                handleAnswer(correct: false)
                                            } else {
                                                // Return to center
                                                withAnimation(.spring()) {
                                                    offset = .zero
                                                    rotation = 0
                                                }
                                            }
                                        }
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isShowingAnswer.toggle()
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    
                    // Answer Buttons
                    if isShowingAnswer {
                        HStack(spacing: 20) {
                            Button(action: { handleAnswer(correct: false) }) {
                                Label("Incorrect", systemImage: "xmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            
                            Button(action: { handleAnswer(correct: true) }) {
                                Label("Correct", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleAnswer(correct: Bool) {
        let flashcard = flashcards[currentIndex]
        
        // Update data
        dataManager.updateFlashcard(flashcard, correct: correct)
        dataManager.recordStudySession()
        
        if correct {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
        
        // Animate card away
        withAnimation(.easeOut(duration: 0.3)) {
            offset = correct ? CGSize(width: 500, height: 0) : CGSize(width: -500, height: 0)
            rotation = correct ? 15 : -15
        }
        
        // Move to next card or complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentIndex < flashcards.count - 1 {
                currentIndex += 1
                isShowingAnswer = false
                offset = .zero
                rotation = 0
            } else {
                isComplete = true
            }
        }
    }
}

// MARK: - Flashcard View
struct FlashcardView: View {
    let flashcard: Flashcard
    let isShowingAnswer: Bool
    
    var body: some View {
        ZStack {
            // Back (Answer)
            VStack(spacing: 16) {
                Text("Answer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(flashcard.answer)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // Difficulty Badge
                HStack {
                    Label(flashcard.difficulty.rawValue, systemImage: "chart.bar.fill")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(difficultyColor(flashcard.difficulty).opacity(0.2))
                        .foregroundStyle(difficultyColor(flashcard.difficulty))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if flashcard.correctCount + flashcard.incorrectCount > 0 {
                        Text("\(Int(flashcard.accuracy))% accuracy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .opacity(isShowingAnswer ? 1 : 0)
            .rotation3DEffect(
                .degrees(isShowingAnswer ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
            
            // Front (Question)
            VStack(spacing: 16) {
                Text("Question")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(flashcard.question)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Text("Tap to reveal answer")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.pink.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .opacity(isShowingAnswer ? 0 : 1)
            .rotation3DEffect(
                .degrees(isShowingAnswer ? -180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
        }
    }
    
    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

#Preview {
    FlashcardStudyView(flashcards: [
        Flashcard(question: "What is SwiftUI?", answer: "A declarative framework for building user interfaces across Apple platforms", documentId: UUID()),
        Flashcard(question: "What is a View in SwiftUI?", answer: "A protocol that defines a piece of user interface", documentId: UUID())
    ])
    .environmentObject(DataManager.shared)
}