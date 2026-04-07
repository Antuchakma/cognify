
import Foundation
import Vision
import UIKit

@MainActor
class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // Configure for best accuracy
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func extractText(from images: [UIImage]) async throws -> String {
        var allText = ""
        
        for (index, image) in images.enumerated() {
            let text = try await extractText(from: image)
            allText += text
            if index < images.count - 1 {
                allText += "\n\n--- Page \(index + 2) ---\n\n"
            }
        }
        
        return allText
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid"
        case .noTextFound:
            return "No text was found in the image"
        case .processingFailed:
            return "Failed to process the image"
        }
    }
}