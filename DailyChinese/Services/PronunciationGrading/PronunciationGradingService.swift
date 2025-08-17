import Foundation

protocol PronunciationGradingService {
    func gradePronounciation(originalText: String, spokenText: String) async throws -> PronunciationGrade
}

struct PronunciationGrade {
    let score: Double // 0.0 to 1.0
    let feedback: String
    let accuracy: AccuracyLevel
    
    enum AccuracyLevel {
        case excellent  // 0.9+
        case good      // 0.7-0.89
        case fair      // 0.5-0.69
        case poor      // <0.5
        
        var description: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Needs Practice"
            }
        }
        
        var emoji: String {
            switch self {
            case .excellent: return "🌟"
            case .good: return "👍"
            case .fair: return "👌"
            case .poor: return "🔄"
            }
        }
    }
}

final class OpenAIPronunciationGradingService: PronunciationGradingService {
    private let urlSession: URLSession
    
    init() {
        self.urlSession = URLSession.shared
    }
    
    func gradePronounciation(originalText: String, spokenText: String) async throws -> PronunciationGrade {
        guard let apiKey = getOpenAIAPIKey() else {
            throw PronunciationGradingError.noAPIKey
        }
        
        let prompt = """
        You are a Chinese pronunciation teacher. Compare the original Chinese text with what the student spoke and provide a pronunciation grade.

        Original text: "\(originalText)"
        Student spoke: "\(spokenText)"

        Analyze:
        1. Character accuracy (how many characters match)
        2. Tone accuracy (if detectable from pinyin/context)
        3. Overall pronunciation quality

        Respond with ONLY a JSON object in this exact format:
        {
            "score": 0.85,
            "feedback": "Good pronunciation! Minor tone issues with '天气'.",
            "reasoning": "8 out of 9 characters correct, good tone on most syllables"
        }

        Score should be 0.0 to 1.0 where:
        - 1.0 = Perfect match
        - 0.8-0.9 = Very good with minor issues
        - 0.6-0.8 = Good with some mistakes
        - 0.4-0.6 = Fair, several mistakes
        - 0.0-0.4 = Poor, major pronunciation issues
        """
        
        let request = OpenAIGradingRequest(
            model: "gpt-4",
            messages: [
                GradingMessage(role: "system", content: "You are a professional Chinese pronunciation teacher. Always respond with valid JSON only."),
                GradingMessage(role: "user", content: prompt)
            ],
            max_tokens: 200,
            temperature: 0.3
        )
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PronunciationGradingError.httpError
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("OpenAI Grading API Error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw PronunciationGradingError.httpError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIGradingResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw PronunciationGradingError.decodingError
        }
        
        // Parse the JSON response from ChatGPT
        guard let responseData = content.data(using: .utf8) else {
            throw PronunciationGradingError.decodingError
        }
        
        let gradingResult = try JSONDecoder().decode(GradingResult.self, from: responseData)
        
        let accuracy: PronunciationGrade.AccuracyLevel
        switch gradingResult.score {
        case 0.9...1.0:
            accuracy = .excellent
        case 0.7..<0.9:
            accuracy = .good
        case 0.5..<0.7:
            accuracy = .fair
        default:
            accuracy = .poor
        }
        
        return PronunciationGrade(
            score: gradingResult.score,
            feedback: gradingResult.feedback,
            accuracy: accuracy
        )
    }
    
    private func getOpenAIAPIKey() -> String? {
        return AppConfig.shared.openAIAPIKey
    }
}

// MARK: - Noop Implementation
final class NoopPronunciationGradingService: PronunciationGradingService {
    func gradePronounciation(originalText: String, spokenText: String) async throws -> PronunciationGrade {
        // Mock grading for previews/testing
        let score = Double.random(in: 0.6...0.95)
        let accuracy: PronunciationGrade.AccuracyLevel
        
        switch score {
        case 0.9...1.0:
            accuracy = .excellent
        case 0.7..<0.9:
            accuracy = .good
        case 0.5..<0.7:
            accuracy = .fair
        default:
            accuracy = .poor
        }
        
        return PronunciationGrade(
            score: score,
            feedback: "Mock feedback: Your pronunciation is \(accuracy.description.lowercased())!",
            accuracy: accuracy
        )
    }
}

// MARK: - Data Types
private struct OpenAIGradingRequest: Codable {
    let model: String
    let messages: [GradingMessage]
    let max_tokens: Int
    let temperature: Double
}

private struct OpenAIGradingResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}

private struct GradingResult: Codable {
    let score: Double
    let feedback: String
    let reasoning: String?
}

private struct GradingMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Errors
enum PronunciationGradingError: Error, LocalizedError {
    case noAPIKey
    case httpError
    case decodingError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .httpError:
            return "HTTP request failed"
        case .decodingError:
            return "Failed to decode response"
        case .invalidResponse:
            return "Invalid response format"
        }
    }
}