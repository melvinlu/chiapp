import Foundation

struct Quiz {
    let id: String
    let questions: [QuizQuestion]
}

struct QuizQuestion {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: Int
}

protocol AIService {
    func suggestExampleUsages(for sentence: String) async throws -> [String]
    func generateQuiz(for packDate: Date) async throws -> Quiz
}

final class NoopAIService: AIService {
    func suggestExampleUsages(for sentence: String) async throws -> [String] {
        return [
            "Example usage placeholder 1",
            "Example usage placeholder 2",
            "Example usage placeholder 3"
        ]
    }
    
    func generateQuiz(for packDate: Date) async throws -> Quiz {
        return Quiz(
            id: UUID().uuidString,
            questions: [
                QuizQuestion(
                    id: "q1",
                    question: "What does '天气' mean?",
                    options: ["Weather", "Time", "Day", "Sky"],
                    correctAnswer: 0
                )
            ]
        )
    }
}