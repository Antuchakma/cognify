
import Foundation

@MainActor
class NetworkService {
    static let shared = NetworkService()
    
    // TODO: Replace with your actual backend URL
    private let baseURL = "http://localhost:3000/api"
    private let aiServiceURL = "http://localhost:8000"
    
    private init() {}
    
    // MARK: - AI Processing
    func generateExplanation(from text: String, level: ExplanationLevel) async throws -> String {
        let endpoint = "\(aiServiceURL)/explain"
        let body: [String: Any] = [
            "text": text,
            "level": level.rawValue
        ]
        
        let response: ExplanationResponse = try await post(endpoint: endpoint, body: body)
        return response.explanation
    }
    
    func generateFlashcards(from text: String, count: Int = 10) async throws -> [FlashcardResponse] {
        let endpoint = "\(aiServiceURL)/generate-flashcards"
        let body: [String: Any] = [
            "text": text,
            "count": count
        ]
        
        let response: FlashcardsGenerationResponse = try await post(endpoint: endpoint, body: body)
        return response.flashcards
    }
    
    func generateQuiz(from text: String, questionCount: Int = 5) async throws -> [QuizQuestionResponse] {
        let endpoint = "\(aiServiceURL)/generate-quiz"
        let body: [String: Any] = [
            "text": text,
            "questionCount": questionCount
        ]
        
        let response: QuizGenerationResponse = try await post(endpoint: endpoint, body: body)
        return response.questions
    }
    
    func analyzeWeaknesses(flashcardResults: [(question: String, correct: Bool)]) async throws -> [String] {
        let endpoint = "\(aiServiceURL)/analyze-weaknesses"
        let body: [String: Any] = [
            "results": flashcardResults.map { ["question": $0.question, "correct": $0.correct] }
        ]
        
        let response: WeaknessAnalysisResponse = try await post(endpoint: endpoint, body: body)
        return response.weakTopics
    }
    
    func semanticSearch(query: String, documents: [String]) async throws -> [SearchResult] {
        let endpoint = "\(aiServiceURL)/search"
        let body: [String: Any] = [
            "query": query,
            "documents": documents
        ]
        
        let response: SearchResponse = try await post(endpoint: endpoint, body: body)
        return response.results
    }
    
    // MARK: - Generic Network Methods
    private func post<T: Decodable>(endpoint: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    private func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Response Models
struct ExplanationResponse: Codable {
    let explanation: String
}

struct FlashcardsGenerationResponse: Codable {
    let flashcards: [FlashcardResponse]
}

struct FlashcardResponse: Codable {
    let question: String
    let answer: String
    let difficulty: String?
}

struct QuizGenerationResponse: Codable {
    let questions: [QuizQuestionResponse]
}

struct QuizQuestionResponse: Codable {
    let question: String
    let options: [String]
    let correctAnswer: String
    let explanation: String?
}

struct WeaknessAnalysisResponse: Codable {
    let weakTopics: [String]
}

struct SearchResponse: Codable {
    let results: [SearchResult]
}

struct SearchResult: Codable {
    let documentId: String
    let content: String
    let relevanceScore: Double
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error with status code: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .noData:
            return "No data received from server"
        }
    }
}