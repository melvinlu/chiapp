import Foundation

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

struct GeneratedSentencesResponse: Codable {
    let sentences: [GeneratedSentence]
}

struct GeneratedSentence: Codable {
    let hanzi: String
    let pinyin: String
    let english: String
    let context: String
    let difficulty: String
}

struct ChinesePodAPIResponse: Codable {
    let sentences: [ChinesePodSentence]
    let date: String
}

struct ChinesePodSentence: Codable {
    let id: String
    let chinese: String
    let pinyin: String
    let english: String
    let audio_url: String?
    let difficulty: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, chinese, pinyin, english, difficulty
        case audio_url = "audio"
    }
}

struct HSKAPIResponse: Codable {
    let sentences: [HSKSentence]
}

struct HSKSentence: Codable {
    let hanzi: String
    let pinyin: String
    let translation: String
    let level: Int
}

final class NetworkRepository: SentenceStore {
    private let urlSession: URLSession
    private let fallbackRepository: LocalRepository
    
    init(urlSession: URLSession = .shared, fallbackRepository: LocalRepository) {
        self.urlSession = urlSession
        self.fallbackRepository = fallbackRepository
    }
    
    func fetchPack(for date: Date) async throws -> [SentenceEntity] {
        return try await fallbackRepository.fetchPack(for: date)
    }
    
    func fetchAllSentences(for date: Date) async throws -> [SentenceEntity] {
        return try await fallbackRepository.fetchAllSentences(for: date)
    }
    
    func upsert(_ sentence: SentenceEntity) async throws {
        try await fallbackRepository.upsert(sentence)
    }
    
    func toggleLearned(id: String) async throws {
        try await fallbackRepository.toggleLearned(id: id)
    }
    
    func toggleFavorite(id: String) async throws {
        try await fallbackRepository.toggleFavorite(id: id)
    }
    
    func delete(_ sentence: SentenceEntity) async throws {
        try await fallbackRepository.delete(sentence)
    }
    
    func seedIfEmpty() async throws {
        let todaysSentences = try await fallbackRepository.fetchPack(for: Date())
        if !todaysSentences.isEmpty {
            return
        }
        
        do {
            let dailySentences = try await fetchDailySentences()
            for sentence in dailySentences {
                try await fallbackRepository.upsert(sentence)
            }
            print("✅ Successfully fetched \(dailySentences.count) daily sentences from network")
        } catch {
            print("⚠️ Network fetch failed, falling back to local seed: \(error)")
            try await fallbackRepository.seedIfEmpty()
        }
    }
    
    func refreshDailySentences() async throws {
        print("🌐 NetworkRepository: Starting refresh...")
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let existingTodaysSentences = try await fallbackRepository.fetchPack(for: today)
        print("🌐 Found \(existingTodaysSentences.count) existing sentences for today")
        
        // Always fetch new sentences for refresh
        print("🌐 Fetching new sentences...")
        
        do {
            print("🌐 Calling fetchDailySentences()...")
            let dailySentences = try await fetchDailySentences()
            print("🌐 Got \(dailySentences.count) new sentences")
            
            // Simply insert new sentences - no deletion needed
            for sentence in dailySentences {
                try await fallbackRepository.upsert(sentence)
            }
            print("🔄 Successfully refreshed with \(dailySentences.count) new daily sentences")
        } catch {
            print("❌ Failed to refresh daily sentences: \(error)")
            throw error
        }
    }
    
    private func deleteSentence(_ sentence: SentenceEntity) async throws {
        try await fallbackRepository.delete(sentence)
    }
    
    private func fetchDailySentences() async throws -> [SentenceEntity] {
        print("📱 fetchDailySentences: Starting...")
        
        // Try ChatGPT only and show detailed error if it fails
        print("📱 Trying ChatGPT only for debugging...")
        do {
            let sentences = try await fetchFromChatGPT()
            print("✅ ChatGPT succeeded with \(sentences.count) sentences")
            return Array(sentences.prefix(5))
        } catch {
            print("❌ ChatGPT failed with detailed error: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Fall back to curated sentences
            print("📱 Falling back to curated sentences...")
            return try await fetchCuratedSentences()
        }
    }
    
    private func fetchFromChatGPT() async throws -> [SentenceEntity] {
        print("🤖 Attempting to fetch from ChatGPT...")
        guard let apiKey = getOpenAIAPIKey() else {
            print("❌ No API key found")
            throw NetworkError.noAPIKey
        }
        print("🤖 API key found, making request...")
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let todayString = dateFormatter.string(from: Date())
        
        let prompt = """
        Generate exactly 5 real-world Chinese sentences for Chinese language learners for \(todayString). 
        
        Requirements:
        - Mix of difficulty levels (HSK 3-5)
        - Practical, everyday situations
        - Include workplace, daily life, cultural contexts
        - Each sentence should be 8-20 characters
        - Provide accurate pinyin with tone marks
        - Natural English translations
        
        Return ONLY a valid JSON response in this exact format:
        {
          "sentences": [
            {
              "hanzi": "Chinese characters here",
              "pinyin": "Accurate pinyin with tone marks",
              "english": "Natural English translation",
              "context": "workplace|daily_life|cultural|social",
              "difficulty": "HSK3|HSK4|HSK5"
            }
          ]
        }
        
        Make sure each sentence is genuinely useful for learners and represents real Chinese usage.
        """
        
        let request = OpenAIRequest(
            model: "gpt-4",
            messages: [
                OpenAIMessage(role: "system", content: "You are a professional Chinese language teacher creating daily practice sentences for intermediate learners."),
                OpenAIMessage(role: "user", content: prompt)
            ],
            max_tokens: 1500,
            temperature: 0.7
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestData = try JSONEncoder().encode(request)
        urlRequest.httpBody = requestData
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.httpError
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("OpenAI API Error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response: \(errorString)")
            }
            throw NetworkError.httpError
        }
        
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = openAIResponse.choices.first?.message.content else {
            throw NetworkError.noData
        }
        
        print("ChatGPT Response: \(content)")
        
        guard let jsonData = content.data(using: .utf8) else {
            throw NetworkError.decodingError
        }
        
        let generatedResponse = try JSONDecoder().decode(GeneratedSentencesResponse.self, from: jsonData)
        
        return generatedResponse.sentences.enumerated().map { index, sentence in
            SentenceEntity(
                id: "chatgpt-\(Date().timeIntervalSince1970)-\(index)",
                hanzi: sentence.hanzi,
                pinyin: sentence.pinyin,
                english: sentence.english,
                packDate: Date(),
                indexInPack: index + 1
            )
        }
    }
    
    private func getOpenAIAPIKey() -> String? {
        // Try to get from environment variables first
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return apiKey
        }
        
        // Try to get from UserDefaults (for user-configured keys)
        if let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") {
            return apiKey
        }
        
        // Hardcoded API key
        return "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"
    }
    
    private func fetchFromChinesePod() async throws -> [SentenceEntity] {
        let urlString = "https://chinesepod.com/api/daily-sentences"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError
        }
        
        let apiResponse = try JSONDecoder().decode(ChinesePodAPIResponse.self, from: data)
        
        return apiResponse.sentences.enumerated().map { index, sentence in
            SentenceEntity(
                id: "pod-\(sentence.id)",
                hanzi: sentence.chinese,
                pinyin: sentence.pinyin,
                english: sentence.english,
                packDate: Date(),
                indexInPack: index + 1,
                audioURL: sentence.audio_url.flatMap(URL.init)
            )
        }
    }
    
    private func fetchFromDuChineseAPI() async throws -> [SentenceEntity] {
        let urlString = "https://app.duchinese.net/api/sentences/daily"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError
        }
        
        let sentences = try JSONDecoder().decode([DuChineseSentence].self, from: data)
        
        return sentences.enumerated().map { index, sentence in
            SentenceEntity(
                id: "du-\(sentence.id)",
                hanzi: sentence.text,
                pinyin: sentence.pinyin,
                english: sentence.translation,
                packDate: Date(),
                indexInPack: index + 1
            )
        }
    }
    
    private func fetchFromHSKSentences() async throws -> [SentenceEntity] {
        let level = Int.random(in: 1...6)
        let urlString = "https://hsk-sentences-api.vercel.app/api/sentences?level=\(level)&limit=5"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError
        }
        
        let apiResponse = try JSONDecoder().decode(HSKAPIResponse.self, from: data)
        
        return apiResponse.sentences.enumerated().map { index, sentence in
            SentenceEntity(
                id: "hsk-\(UUID().uuidString)",
                hanzi: sentence.hanzi,
                pinyin: sentence.pinyin,
                english: sentence.translation,
                packDate: Date(),
                indexInPack: index + 1
            )
        }
    }
    
    private func fetchCuratedSentences() async throws -> [SentenceEntity] {
        let curatedSentences = [
            ("今天北京的空气质量不太好，建议戴口罩出门。", "Jīntiān Běijīng de kōngqì zhìliàng bù tài hǎo, jiànyì dài kǒuzhào chūmén.", "Today's air quality in Beijing isn't very good, it's recommended to wear a mask when going out."),
            ("这家餐厅的招牌菜是麻婆豆腐，非常正宗。", "Zhè jiā cāntīng de zhāopáicài shì mápó dòufu, fēicháng zhèngzōng.", "This restaurant's signature dish is mapo tofu, it's very authentic."),
            ("我刚刚在地铁里丢了手机，正在找失物招领处。", "Wǒ gānggāng zài dìtiě lǐ diūle shǒujī, zhèngzài zhǎo shīwù zhāolǐng chù.", "I just lost my phone on the subway and I'm looking for the lost and found."),
            ("春节期间，很多商店都会放假回家过年。", "Chūnjié qījiān, hěnduō shāngdiàn dōu huì fàngjià huí jiā guònián.", "During Spring Festival, many shops will close and people go home to celebrate the New Year."),
            ("学会使用筷子需要一些练习，但是并不难。", "Xuéhuì shǐyòng kuàizi xūyào yīxiē liànxí, dànshì bìng bù nán.", "Learning to use chopsticks requires some practice, but it's not difficult.")
        ]
        
        let timestamp = Date().timeIntervalSince1970
        let shuffledSentences = curatedSentences.shuffled()
        return shuffledSentences.prefix(5).enumerated().map { (index, tuple) in
            let (hanzi, pinyin, english) = tuple
            return SentenceEntity(
                id: "curated-\(timestamp)-\(index)",
                hanzi: hanzi,
                pinyin: pinyin,
                english: english,
                packDate: Date(),
                indexInPack: index + 1
            )
        }
    }
    
    private func generateDailySentences() -> [SentenceEntity] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        let dailyRotatingContent = [
            // Business/Work Context
            [
                ("我们公司最近搬到了新的办公楼，环境比以前好多了。", "Wǒmen gōngsī zuìjìn bāndàole xīn de bàngōnglóu, huánjìng bǐ yǐqián hǎo duōle.", "Our company recently moved to a new office building, the environment is much better than before."),
                ("今天的会议讨论了下个季度的销售目标。", "Jīntiān de huìyì tǎolùnle xià gè jìdù de xiāoshòu mùbiāo.", "Today's meeting discussed next quarter's sales targets."),
                ("老板说如果项目成功的话，大家都会有奖金。", "Lǎobǎn shuō rúguǒ xiàngmù chénggōng de huà, dàjiā dōu huì yǒu jiǎngjīn.", "The boss said if the project succeeds, everyone will get a bonus."),
                ("我正在学习新的软件，希望能提高工作效率。", "Wǒ zhèngzài xuéxí xīn de ruǎnjiàn, xīwàng néng tígāo gōngzuò xiàolǜ.", "I'm learning new software, hoping to improve work efficiency."),
                ("同事们邀请我参加周末的团建活动。", "Tóngshìmen yāoqǐng wǒ cānjiā zhōumò de tuánjiàn huódòng.", "My colleagues invited me to join the weekend team-building activity.")
            ],
            // Daily Life Context
            [
                ("超市里的蔬菜很新鲜，价格也比较合理。", "Chāoshì lǐ de shūcài hěn xīnxiān, jiàgé yě bǐjiào hélǐ.", "The vegetables in the supermarket are very fresh and reasonably priced."),
                ("今天天气预报说下午可能会下雨。", "Jīntiān tiānqì yùbào shuō xiàwǔ kěnéng huì xiàyǔ.", "Today's weather forecast says it might rain this afternoon."),
                ("我在健身房办了年卡，打算坚持锻炼身体。", "Wǒ zài jiànshēnfáng bànle niánkǎ, dǎsuàn jiānchí duànliàn shēntǐ.", "I got an annual membership at the gym and plan to stick to exercising."),
                ("邻居家的小狗很可爱，每天都会跟我打招呼。", "Línjū jiā de xiǎogǒu hěn kě'ài, měitiān dōu huì gēn wǒ dǎ zhāohū.", "My neighbor's little dog is very cute and greets me every day."),
                ("周末我喜欢在家里做饭，尝试不同的菜谱。", "Zhōumò wǒ xǐhuan zài jiālǐ zuòfàn, chángshì bùtóng de càipǔ.", "On weekends I like to cook at home and try different recipes.")
            ],
            // Cultural/Social Context
            [
                ("春节期间，大家都忙着准备年夜饭。", "Chūnjié qījiān, dàjiā dōu mángzhe zhǔnbèi niányèfàn.", "During Spring Festival, everyone is busy preparing the New Year's Eve dinner."),
                ("这个电视剧最近很受欢迎，朋友们都在讨论剧情。", "Zhège diànshìjù zuìjìn hěn shòu huānyíng, péngyǒumen dōu zài tǎolùn jùqíng.", "This TV drama is very popular recently, friends are all discussing the plot."),
                ("中国的高铁速度很快，从北京到上海只需要几个小时。", "Zhōngguó de gāotiě sùdù hěn kuài, cóng Běijīng dào Shànghǎi zhǐ xūyào jǐ gè xiǎoshí.", "China's high-speed rail is very fast, it only takes a few hours from Beijing to Shanghai."),
                ("现在很多人喜欢用手机支付，现金用得越来越少了。", "Xiànzài hěnduō rén xǐhuan yòng shǒujī zhīfù, xiànjīn yòng dé yuèláiyuè shǎole.", "Now many people like to pay with their phones, cash is used less and less."),
                ("学习汉语的外国人越来越多，中文学校也在增加。", "Xuéxí Hànyǔ de wàiguórén yuèláiyuè duō, zhōngwén xuéxiào yě zài zēngjiā.", "More and more foreigners are learning Chinese, and Chinese schools are also increasing.")
            ]
        ]
        
        let dayOfYear = Calendar.current.ordinDay(for: Date()) ?? 1
        let selectedContent = dailyRotatingContent[dayOfYear % dailyRotatingContent.count]
        
        return selectedContent.enumerated().map { (index, tuple) in
            let (hanzi, pinyin, english) = tuple
            return SentenceEntity(
                id: "daily-\(dateString)-\(index + 1)",
                hanzi: hanzi,
                pinyin: pinyin,
                english: english,
                packDate: Date(),
                indexInPack: index + 1
            )
        }
    }
}

struct DuChineseSentence: Codable {
    let id: String
    let text: String
    let pinyin: String
    let translation: String
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case httpError
    case decodingError
    case noData
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .httpError:
            return "HTTP request failed"
        case .decodingError:
            return "Failed to decode response"
        case .noData:
            return "No data available"
        case .noAPIKey:
            return "OpenAI API key not configured"
        }
    }
}

extension Calendar {
    func ordinDay(for date: Date) -> Int? {
        return self.ordinality(of: .day, in: .year, for: date)
    }
}