
import Foundation

/// Mock service for testing without backend
/// Set USE_MOCK_DATA to true in NetworkService to enable
@MainActor
class MockDataService {
    static let shared = MockDataService()
    
    private init() {}
    
    func generateExplanation(from text: String, level: ExplanationLevel) async throws -> String {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1.5))
        
        switch level {
        case .beginner:
            return """
            This content explains fundamental concepts in a simple way.
            
            Key Points:
            â€¢ Break down complex topics into simple terms
            â€¢ Use everyday examples to illustrate concepts
            â€¢ Focus on building foundational understanding
            
            Think of it like learning to ride a bike - you start with training wheels before attempting advanced tricks!
            """
            
        case .detailed:
            return """
            This is a comprehensive explanation that dives deep into the subject matter.
            
            Overview:
            The content covers multiple aspects of the topic, providing context, examples, and connections to related concepts.
            
            Key Components:
            1. Core principles and their applications
            2. Real-world examples and case studies
            3. Common misconceptions and clarifications
            4. Advanced considerations
            
            This level of detail helps build mastery through thorough understanding.
            """
            
        case .examFocused:
            return """
            Exam-Ready Summary:
            
            âš¡ Key Facts to Remember:
            â€¢ Most important concepts appear in 80% of exams
            â€¢ Focus on definitions, formulas, and core principles
            â€¢ Practice application problems
            
            ðŸ“ Common Exam Questions:
            - Define and explain core terms
            - Apply concepts to solve problems
            - Compare and contrast related ideas
            
            ðŸ’¡ Study Tips:
            â€¢ Create summary sheets
            â€¢ Practice past papers
            â€¢ Time yourself on practice questions
            
            This format prioritizes exam success with focused review.
            """
        }
    }
    
    func generateFlashcards(from text: String, count: Int) async throws -> [FlashcardResponse] {
        // Simulate network delay
        try await Task.sleep(for: .seconds(2))
        
        // Generate sample flashcards based on the text
        let sampleFlashcards = [
            FlashcardResponse(
                question: "What is the main topic discussed in the text?",
                answer: "The text discusses key concepts and their applications in real-world scenarios.",
                difficulty: "Medium"
            ),
            FlashcardResponse(
                question: "What are the key principles mentioned?",
                answer: "Core principles include understanding fundamentals, applying concepts practically, and continuous learning.",
                difficulty: "Easy"
            ),
            FlashcardResponse(
                question: "How can these concepts be applied?",
                answer: "These concepts can be applied through hands-on practice, real projects, and systematic study.",
                difficulty: "Hard"
            ),
            FlashcardResponse(
                question: "What is the importance of understanding this material?",
                answer: "Understanding this material builds foundational knowledge necessary for advanced topics and practical applications.",
                difficulty: "Medium"
            ),
            FlashcardResponse(
                question: "What study strategies are recommended?",
                answer: "Recommended strategies include spaced repetition, active recall, and regular practice with varied examples.",
                difficulty: "Easy"
            ),
            FlashcardResponse(
                question: "What common mistakes should be avoided?",
                answer: "Common mistakes include superficial learning, skipping practice, and not connecting concepts to real applications.",
                difficulty: "Medium"
            ),
            FlashcardResponse(
                question: "How does this relate to broader concepts?",
                answer: "This material connects to broader concepts by providing building blocks that support more complex understanding.",
                difficulty: "Hard"
            ),
            FlashcardResponse(
                question: "What are the practical implications?",
                answer: "Practical implications include improved problem-solving skills, better decision-making, and enhanced critical thinking.",
                difficulty: "Medium"
            ),
            FlashcardResponse(
                question: "What prerequisites are needed?",
                answer: "Prerequisites include basic understanding of fundamental concepts and willingness to engage with new material.",
                difficulty: "Easy"
            ),
            FlashcardResponse(
                question: "What advanced topics does this lead to?",
                answer: "This material leads to advanced topics such as specialized applications, research areas, and professional practices.",
                difficulty: "Hard"
            )
        ]
        
        return Array(sampleFlashcards.prefix(min(count, sampleFlashcards.count)))
    }
    
    func generateQuiz(from text: String, questionCount: Int) async throws -> [QuizQuestionResponse] {
        // Simulate network delay
        try await Task.sleep(for: .seconds(2))
        
        let sampleQuestions = [
            QuizQuestionResponse(
                question: "What is the primary purpose of studying this material?",
                options: [
                    "To memorize facts",
                    "To understand concepts and apply them",
                    "To pass exams only",
                    "To impress others"
                ],
                correctAnswer: "To understand concepts and apply them",
                explanation: "True learning involves understanding and application, not just memorization."
            ),
            QuizQuestionResponse(
                question: "Which learning strategy is most effective?",
                options: [
                    "Cramming the night before",
                    "Passive reading",
                    "Spaced repetition and active recall",
                    "Highlighting everything"
                ],
                correctAnswer: "Spaced repetition and active recall",
                explanation: "Research shows that spaced repetition and active recall lead to better long-term retention."
            ),
            QuizQuestionResponse(
                question: "What indicates deep understanding of a topic?",
                options: [
                    "Memorizing definitions",
                    "Reading the material once",
                    "Explaining it to others and applying it",
                    "Writing notes"
                ],
                correctAnswer: "Explaining it to others and applying it",
                explanation: "Being able to teach others and apply knowledge demonstrates true understanding."
            ),
            QuizQuestionResponse(
                question: "How should you approach difficult concepts?",
                options: [
                    "Skip them and move on",
                    "Read them once quickly",
                    "Break them down and practice repeatedly",
                    "Wait for someone to explain"
                ],
                correctAnswer: "Break them down and practice repeatedly",
                explanation: "Complex concepts become manageable when broken into smaller parts and practiced."
            ),
            QuizQuestionResponse(
                question: "What is the best way to prepare for exams?",
                options: [
                    "Study only the day before",
                    "Regular study with practice tests",
                    "Just attend lectures",
                    "Copy someone's notes"
                ],
                correctAnswer: "Regular study with practice tests",
                explanation: "Consistent study combined with practice testing leads to better exam performance."
            )
        ]
        
        return Array(sampleQuestions.prefix(min(questionCount, sampleQuestions.count)))
    }
    
    func analyzeWeaknesses(flashcardResults: [(question: String, correct: Bool)]) async throws -> [String] {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1))
        
        // Mock weakness analysis
        let incorrectQuestions = flashcardResults.filter { !$0.correct }
        
        if incorrectQuestions.isEmpty {
            return ["Great job! No weak areas detected."]
        }
        
        // Extract mock topics from questions
        var weakTopics: [String] = []
        
        for result in incorrectQuestions.prefix(3) {
            let words = result.question.split(separator: " ").prefix(3)
            let topic = words.joined(separator: " ")
            if !weakTopics.contains(topic) {
                weakTopics.append(topic)
            }
        }
        
        return weakTopics.isEmpty ? ["Review all topics"] : weakTopics
    }
}

/// Extension to make NetworkService use mock data for testing
extension NetworkService {
    // Set this to true to use mock data
    static var USE_MOCK_DATA = false
    
    func generateExplanationWithFallback(from text: String, level: ExplanationLevel) async throws -> String {
        if NetworkService.USE_MOCK_DATA {
            return try await MockDataService.shared.generateExplanation(from: text, level: level)
        }
        return try await generateExplanation(from: text, level: level)
    }
    
    func generateFlashcardsWithFallback(from text: String, count: Int = 10) async throws -> [FlashcardResponse] {
        if NetworkService.USE_MOCK_DATA {
            return try await MockDataService.shared.generateFlashcards(from: text, count: count)
        }
        return try await generateFlashcards(from: text, count: count)
    }
    
    func generateQuizWithFallback(from text: String, questionCount: Int = 5) async throws -> [QuizQuestionResponse] {
        if NetworkService.USE_MOCK_DATA {
            return try await MockDataService.shared.generateQuiz(from: text, questionCount: questionCount)
        }
        return try await generateQuiz(from: text, questionCount: questionCount)
    }
}