#!/usr/bin/env swift

import Foundation

let apiKey = "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"

struct OpenAIRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let max_tokens: Int
    let temperature: Double
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

func testChatGPT() async {
    print("🧪 Testing ChatGPT API...")
    
    let url = URL(string: "https://api.openai.com/v1/chat/completions")!
    
    let prompt = """
    Generate exactly 2 simple Chinese sentences for testing. Return ONLY valid JSON:
    {
      "sentences": [
        {
          "hanzi": "你好",
          "pinyin": "nǐ hǎo", 
          "english": "Hello",
          "context": "daily_life",
          "difficulty": "HSK1"
        }
      ]
    }
    """
    
    let request = OpenAIRequest(
        model: "gpt-4",
        messages: [
            OpenAIMessage(role: "system", content: "You are a Chinese language teacher."),
            OpenAIMessage(role: "user", content: prompt)
        ],
        max_tokens: 500,
        temperature: 0.7
    )
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    do {
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        print("🤖 Making API request...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response status: \(httpResponse.statusCode)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📝 Response data: \(responseString)")
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        if let content = openAIResponse.choices.first?.message.content {
            print("✅ ChatGPT Response: \(content)")
        }
        
    } catch {
        print("❌ Error: \(error)")
    }
}

await testChatGPT()
print("🎯 Test complete")