
import Foundation
import SwiftUI

// MARK: - Document Model
struct Document: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var type: DocumentType
    var createdAt: Date
    var thumbnailData: Data?
    var processedByAI: Bool
    
    init(id: UUID = UUID(), title: String, content: String, type: DocumentType, createdAt: Date = Date(), thumbnailData: Data? = nil, processedByAI: Bool = false) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.createdAt = createdAt
        self.thumbnailData = thumbnailData
        self.processedByAI = processedByAI
    }
}

enum DocumentType: String, Codable {
    case pdf = "PDF"
    case image = "Image"
    case text = "Text"
}

// MARK: - Flashcard Model
struct Flashcard: Identifiable, Codable {
    let id: UUID
    var question: String
    var answer: String
    var documentId: UUID
    var difficulty: Difficulty
    var lastReviewed: Date?
    var correctCount: Int
    var incorrectCount: Int
    var nextReviewDate: Date?
    
    init(id: UUID = UUID(), question: String, answer: String, documentId: UUID, difficulty: Difficulty = .medium, lastReviewed: Date? = nil, correctCount: Int = 0, incorrectCount: Int = 0, nextReviewDate: Date? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.documentId = documentId
        self.difficulty = difficulty
        self.lastReviewed = lastReviewed
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.nextReviewDate = nextReviewDate
    }
    
    var accuracy: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total) * 100
    }
}

enum Difficulty: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

// MARK: - Quiz Model
struct Quiz: Identifiable, Codable {
    let id: UUID
    var title: String
    var documentId: UUID
    var questions: [QuizQuestion]
    var createdAt: Date
    var completed: Bool
    var score: Double?
    
    init(id: UUID = UUID(), title: String, documentId: UUID, questions: [QuizQuestion], createdAt: Date = Date(), completed: Bool = false, score: Double? = nil) {
        self.id = id
        self.title = title
        self.documentId = documentId
        self.questions = questions
        self.createdAt = createdAt
        self.completed = completed
        self.score = score
    }
}

struct QuizQuestion: Identifiable, Codable {
    let id: UUID
    var question: String
    var options: [String]
    var correctAnswer: String
    var explanation: String?
    var userAnswer: String?
    
    init(id: UUID = UUID(), question: String, options: [String], correctAnswer: String, explanation: String? = nil, userAnswer: String? = nil) {
        self.id = id
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.userAnswer = userAnswer
    }
    
    var isCorrect: Bool? {
        guard let userAnswer = userAnswer else { return nil }
        return userAnswer == correctAnswer
    }
}

// MARK: - User Progress Model
struct UserProgress: Codable {
    var totalDocuments: Int
    var totalFlashcards: Int
    var totalQuizzes: Int
    var currentStreak: Int
    var longestStreak: Int
    var lastStudyDate: Date?
    var overallAccuracy: Double
    var studyMinutes: Int
    
    init(totalDocuments: Int = 0, totalFlashcards: Int = 0, totalQuizzes: Int = 0, currentStreak: Int = 0, longestStreak: Int = 0, lastStudyDate: Date? = nil, overallAccuracy: Double = 0, studyMinutes: Int = 0) {
        self.totalDocuments = totalDocuments
        self.totalFlashcards = totalFlashcards
        self.totalQuizzes = totalQuizzes
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastStudyDate = lastStudyDate
        self.overallAccuracy = overallAccuracy
        self.studyMinutes = studyMinutes
    }
}

// MARK: - AI Response Models
struct AIExplanation: Codable {
    var documentId: UUID
    var explanation: String
    var level: ExplanationLevel
    var generatedAt: Date
    
    init(documentId: UUID, explanation: String, level: ExplanationLevel, generatedAt: Date = Date()) {
        self.documentId = documentId
        self.explanation = explanation
        self.level = level
        self.generatedAt = generatedAt
    }
}

enum ExplanationLevel: String, Codable {
    case beginner = "Beginner"
    case detailed = "Detailed"
    case examFocused = "Exam-Focused"
}

// MARK: - Weak Topic Model
struct WeakTopic: Identifiable, Codable {
    let id: UUID
    var topic: String
    var incorrectCount: Int
    var relatedFlashcards: [UUID]
    
    init(id: UUID = UUID(), topic: String, incorrectCount: Int, relatedFlashcards: [UUID]) {
        self.id = id
        self.topic = topic
        self.incorrectCount = incorrectCount
        self.relatedFlashcards = relatedFlashcards
    }
}
```

### cognify/DataManager.swift
Create file `DataManager.swift` inside `cognify` folder.
```swift
//
//  DataManager.swift
//  cognify
//
//  Created by Kusalab Dewan on 23/3/2026.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class DataManager {
    static let shared = DataManager()
    
    var documents: [Document] = []
    var flashcards: [Flashcard] = []
    var quizzes: [Quiz] = []
    var progress: UserProgress = UserProgress()
    var weakTopics: [WeakTopic] = []
    
    private let documentsKey = "cognify_documents"
    private let flashcardsKey = "cognify_flashcards"
    private let quizzesKey = "cognify_quizzes"
    private let progressKey = "cognify_progress"
    private let weakTopicsKey = "cognify_weak_topics"
    
    private init() {
        loadData()
    }
    
    // MARK: - Load Data
    func loadData() {
        loadDocuments()
        loadFlashcards()
        loadQuizzes()
        loadProgress()
        loadWeakTopics()
    }
    
    private func loadDocuments() {
        if let data = UserDefaults.standard.data(forKey: documentsKey),
           let decoded = try? JSONDecoder().decode([Document].self, from: data) {
            documents = decoded
        }
    }
    
    private func loadFlashcards() {
        if let data = UserDefaults.standard.data(forKey: flashcardsKey),
           let decoded = try? JSONDecoder().decode([Flashcard].self, from: data) {
            flashcards = decoded
        }
    }
    
    private func loadQuizzes() {
        if let data = UserDefaults.standard.data(forKey: quizzesKey),
           let decoded = try? JSONDecoder().decode([Quiz].self, from: data) {
            quizzes = decoded
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let decoded = try? JSONDecoder().decode(UserProgress.self, from: data) {
            progress = decoded
        }
        updateStreak()
    }
    
    private func loadWeakTopics() {
        if let data = UserDefaults.standard.data(forKey: weakTopicsKey),
           let decoded = try? JSONDecoder().decode([WeakTopic].self, from: data) {
            weakTopics = decoded
        }
    }
    
    // MARK: - Save Data
    private func saveDocuments() {
        if let encoded = try? JSONEncoder().encode(documents) {
            UserDefaults.standard.set(encoded, forKey: documentsKey)
        }
    }
    
    private func saveFlashcards() {
        if let encoded = try? JSONEncoder().encode(flashcards) {
            UserDefaults.standard.set(encoded, forKey: flashcardsKey)
        }
    }
    
    private func saveQuizzes() {
        if let encoded = try? JSONEncoder().encode(quizzes) {
            UserDefaults.standard.set(encoded, forKey: quizzesKey)
        }
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(progress) {
            UserDefaults.standard.set(encoded, forKey: progressKey)
        }
    }
    
    private func saveWeakTopics() {
        if let encoded = try? JSONEncoder().encode(weakTopics) {
            UserDefaults.standard.set(encoded, forKey: weakTopicsKey)
        }
    }
    
    // MARK: - Document Methods
    func addDocument(_ document: Document) {
        documents.insert(document, at: 0)
        progress.totalDocuments = documents.count
        saveDocuments()
        saveProgress()
    }
    
    func deleteDocument(_ document: Document) {
        documents.removeAll { $0.id == document.id }
        flashcards.removeAll { $0.documentId == document.id }
        quizzes.removeAll { $0.documentId == document.id }
        progress.totalDocuments = documents.count
        progress.totalFlashcards = flashcards.count
        progress.totalQuizzes = quizzes.count
        saveDocuments()
        saveFlashcards()
        saveQuizzes()
        saveProgress()
    }
    
    // MARK: - Flashcard Methods
    func addFlashcards(_ newFlashcards: [Flashcard]) {
        flashcards.append(contentsOf: newFlashcards)
        progress.totalFlashcards = flashcards.count
        saveFlashcards()
        saveProgress()
    }
    
    func updateFlashcard(_ flashcard: Flashcard, correct: Bool) {
        if let index = flashcards.firstIndex(where: { $0.id == flashcard.id }) {
            if correct {
                flashcards[index].correctCount += 1
            } else {
                flashcards[index].incorrectCount += 1
            }
            flashcards[index].lastReviewed = Date()
            
            // Update next review date based on spaced repetition
            let interval = correct ? calculateNextInterval(for: flashcards[index]) : 1
            flashcards[index].nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: Date())
            
            saveFlashcards()
            updateOverallAccuracy()
        }
    }
    
    private func calculateNextInterval(for flashcard: Flashcard) -> Int {
        // Simple spaced repetition algorithm
        let accuracy = flashcard.accuracy
        if accuracy >= 90 {
            return 7 // Review in 1 week
        } else if accuracy >= 70 {
            return 3 // Review in 3 days
        } else {
            return 1 // Review tomorrow
        }
    }
    
    func getFlashcards(for documentId: UUID) -> [Flashcard] {
        return flashcards.filter { $0.documentId == documentId }
    }
    
    func getFlashcardsDueForReview() -> [Flashcard] {
        let today = Date()
        return flashcards.filter { flashcard in
            guard let nextReview = flashcard.nextReviewDate else { return true }
            return nextReview <= today
        }
    }
    
    // MARK: - Quiz Methods
    func addQuiz(_ quiz: Quiz) {
        quizzes.insert(quiz, at: 0)
        progress.totalQuizzes = quizzes.count
        saveQuizzes()
        saveProgress()
    }
    
    func updateQuiz(_ quiz: Quiz) {
        if let index = quizzes.firstIndex(where: { $0.id == quiz.id }) {
            quizzes[index] = quiz
            saveQuizzes()
            updateOverallAccuracy()
        }
    }
    
    func getQuizzes(for documentId: UUID) -> [Quiz] {
        return quizzes.filter { $0.documentId == documentId }
    }
    
    // MARK: - Progress Methods
    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastStudy = progress.lastStudyDate else {
            // First time studying
            return
        }
        
        let lastStudyDay = calendar.startOfDay(for: lastStudy)
        let daysSinceLastStudy = calendar.dateComponents([.day], from: lastStudyDay, to: today).day ?? 0
        
        if daysSinceLastStudy == 0 {
            // Already studied today
            return
        } else if daysSinceLastStudy == 1 {
            // Studied yesterday, increment streak
            progress.currentStreak += 1
            if progress.currentStreak > progress.longestStreak {
                progress.longestStreak = progress.currentStreak
            }
        } else {
            // Streak broken
            progress.currentStreak = 1
        }
        
        saveProgress()
    }
    
    func recordStudySession() {
        progress.lastStudyDate = Date()
        updateStreak()
        saveProgress()
    }
    
    private func updateOverallAccuracy() {
        let totalCorrect = flashcards.reduce(0) { $0 + $1.correctCount }
        let totalIncorrect = flashcards.reduce(0) { $0 + $1.incorrectCount }
        let total = totalCorrect + totalIncorrect
        
        if total > 0 {
            progress.overallAccuracy = Double(totalCorrect) / Double(total) * 100
        }
        
        saveProgress()
    }
    
    // MARK: - Weak Topics
    func analyzeWeakTopics() {
        // This would be more sophisticated in production
        // For now, we'll identify topics from flashcards with low accuracy
        var topicMap: [String: (incorrect: Int, flashcards: [UUID])] = [:]
        
        for flashcard in flashcards where flashcard.accuracy < 60 {
            // Extract topic from question (simplified - in production, use NLP)
            let topic = extractTopic(from: flashcard.question)
            if var existing = topicMap[topic] {
                existing.incorrect += flashcard.incorrectCount
                existing.flashcards.append(flashcard.id)
                topicMap[topic] = existing
            } else {
                topicMap[topic] = (flashcard.incorrectCount, [flashcard.id])
            }
        }
        
        weakTopics = topicMap.map { topic, data in
            WeakTopic(topic: topic, incorrectCount: data.incorrect, relatedFlashcards: data.flashcards)
        }.sorted { $0.incorrectCount > $1.incorrectCount }
        
        saveWeakTopics()
    }
    
    private func extractTopic(from text: String) -> String {
        // Simplified topic extraction - take first few words
        let words = text.split(separator: " ").prefix(3)
        return words.joined(separator: " ")
    }
}