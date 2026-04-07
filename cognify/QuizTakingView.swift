import SwiftUI

struct QuizTakingView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var quiz: Quiz
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String?
    @State private var showingResult = false
    @State private var isComplete = false
    
    init(quiz: Quiz) {
        _quiz = State(initialValue: quiz)
    }
    
    var currentQuestion: QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isComplete {
                    // Results View
                    ScrollView {
                        VStack(spacing: 24) {
                            // Score Header
                            VStack(spacing: 12) {
                                Image(systemName: scoreIcon)
                                    .font(.system(size: 60))
                                    .foregroundStyle(scoreColor)
                                
                                Text("\(Int(quiz.score ?? 0))%")
                                    .font(.system(size: 48, weight: .bold))
                                
                                Text(scoreMessage)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            
                            // Summary
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Correct")
                                    Spacer()
                                    Text("\(correctAnswersCount) / \(quiz.questions.count)")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Score")
                                    Spacer()
                                    Text("\(Int(quiz.score ?? 0))%")
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                            
                            // Question Review
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Review")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(Array(quiz.questions.enumerated()), id: \.element.id) { index, question in
                                    QuestionReviewCard(question: question, number: index + 1)
                                        .padding(.horizontal)
                                }
                            }
                            
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                        .padding(.vertical)
                    }
                } else {
                    // Quiz Taking View
                    VStack(spacing: 0) {
                        // Progress Header
                        VStack(spacing: 12) {
                            HStack {
                                Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                                    .font(.headline)
                                Spacer()
                                Text("\(answeredCount) answered")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            ProgressView(value: Double(currentQuestionIndex + 1), total: Double(quiz.questions.count))
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        
                        Divider()
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                // Question
                                Text(currentQuestion.question)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .padding()
                                
                                // Options
                                VStack(spacing: 12) {
                                    ForEach(currentQuestion.options, id: \.self) { option in
                                        OptionButton(
                                            option: option,
                                            isSelected: selectedAnswer == option,
                                            isCorrect: showingResult ? option == currentQuestion.correctAnswer : nil,
                                            isWrong: showingResult ? (selectedAnswer == option && option != currentQuestion.correctAnswer) : false
                                        ) {
                                            if !showingResult {
                                                selectedAnswer = option
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Explanation (shown after answer)
                                if showingResult, let explanation = currentQuestion.explanation {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Label("Explanation", systemImage: "info.circle.fill")
                                            .font(.headline)
                                            .foregroundStyle(.blue)
                                        
                                        Text(explanation)
                                            .font(.body)
                                    }
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        
                        // Action Button
                        VStack {
                            Divider()
                            
                            if showingResult {
                                Button(action: nextQuestion) {
                                    Text(currentQuestionIndex < quiz.questions.count - 1 ? "Next Question" : "Finish Quiz")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .padding()
                            } else {
                                Button(action: submitAnswer) {
                                    Text("Submit Answer")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(selectedAnswer == nil)
                                .padding()
                            }
                        }
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle(quiz.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isComplete {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private var answeredCount: Int {
        quiz.questions.filter { $0.userAnswer != nil }.count
    }
    
    private var correctAnswersCount: Int {
        quiz.questions.filter { $0.isCorrect == true }.count
    }
    
    private var scoreIcon: String {
        guard let score = quiz.score else { return "questionmark.circle" }
        if score >= 80 { return "star.fill" }
        if score >= 60 { return "hand.thumbsup.fill" }
        return "arrow.clockwise"
    }
    
    private var scoreColor: Color {
        guard let score = quiz.score else { return .gray }
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private var scoreMessage: String {
        guard let score = quiz.score else { return "Let's begin!" }
        if score >= 80 { return "Excellent work!" }
        if score >= 60 { return "Good job!" }
        return "Keep practicing!"
    }
    
    private func submitAnswer() {
        guard let answer = selectedAnswer else { return }
        
        // Save user's answer
        quiz.questions[currentQuestionIndex].userAnswer = answer
        
        withAnimation {
            showingResult = true
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < quiz.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = quiz.questions[currentQuestionIndex].userAnswer
            showingResult = selectedAnswer != nil
        } else {
            completeQuiz()
        }
    }
    
    private func completeQuiz() {
        // Calculate score
        let correct = correctAnswersCount
        let total = quiz.questions.count
        let score = Double(correct) / Double(total) * 100
        
        quiz.score = score
        quiz.completed = true
        
        // Update in data manager
        dataManager.updateQuiz(quiz)
        dataManager.recordStudySession()
        
        withAnimation {
            isComplete = true
        }
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool?
    let isWrong: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(textColor)
                
                Spacer()
                
                if let isCorrect = isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isWrong ? "xmark.circle.fill" : ""))
                        .foregroundStyle(isCorrect ? .green : .red)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? Color.green.opacity(0.1) : (isWrong ? Color.red.opacity(0.1) : Color(.systemGray6))
        }
        return isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6)
    }
    
    private var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : (isWrong ? .red : .clear)
        }
        return isSelected ? .blue : .clear
    }
    
    private var textColor: Color {
        if isCorrect == true {
            return .green
        } else if isWrong {
            return .red
        }
        return .primary
    }
}

// MARK: - Question Review Card
struct QuestionReviewCard: View {
    let question: QuizQuestion
    let number: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Q\(number)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(question.isCorrect == true ? Color.green : Color.red)
                    .clipShape(Capsule())
                
                Spacer()
                
                Image(systemName: question.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(question.isCorrect == true ? .green : .red)
            }
            
            Text(question.question)
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Your answer:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(question.userAnswer ?? "No answer")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if question.isCorrect == false {
                    HStack {
                        Text("Correct answer:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(question.correctAnswer)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    QuizTakingView(quiz: Quiz(
        title: "Sample Quiz",
        documentId: UUID(),
        questions: [
            QuizQuestion(
                question: "What is SwiftUI?",
                options: ["A framework", "A language", "A tool", "An IDE"],
                correctAnswer: "A framework",
                explanation: "SwiftUI is Apple's declarative framework for building user interfaces."
            ),
            QuizQuestion(
                question: "Which keyword is used for asynchronous functions?",
                options: ["await", "async", "defer", "task"],
                correctAnswer: "async"
            )
        ]
    ))
    .environmentObject(DataManager.shared)
}