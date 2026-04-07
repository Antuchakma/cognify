
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