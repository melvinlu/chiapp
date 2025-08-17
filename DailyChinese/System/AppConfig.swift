import Foundation

struct AppConfig {
    static let shared = AppConfig()
    
    private init() {}
    
    var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    var defaultLanguageCode: String {
        "zh-CN"
    }
    
    var ttsRate: Float {
        UserDefaults.standard.object(forKey: "tts_rate") as? Float ?? 0.45
    }
    
    var ttsPitch: Float {
        UserDefaults.standard.object(forKey: "tts_pitch") as? Float ?? 1.0
    }
    
    var dailySentenceCount: Int {
        UserDefaults.standard.object(forKey: "daily_sentence_count") as? Int ?? 10
    }
    
    var enableAIFeatures: Bool {
        UserDefaults.standard.bool(forKey: "enable_ai_features")
    }
    
    var enableRecordingFeatures: Bool {
        UserDefaults.standard.bool(forKey: "enable_recording_features")
    }
    
    var enableAnalytics: Bool {
        UserDefaults.standard.bool(forKey: "enable_analytics")
    }
    
    func updateTTSRate(_ rate: Float) {
        UserDefaults.standard.set(rate, forKey: "tts_rate")
    }
    
    func updateTTSPitch(_ pitch: Float) {
        UserDefaults.standard.set(pitch, forKey: "tts_pitch")
    }
    
    func updateDailySentenceCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: "daily_sentence_count")
    }
    
    func toggleAIFeatures() {
        let current = enableAIFeatures
        UserDefaults.standard.set(!current, forKey: "enable_ai_features")
    }
    
    func toggleRecordingFeatures() {
        let current = enableRecordingFeatures
        UserDefaults.standard.set(!current, forKey: "enable_recording_features")
    }
    
    func toggleAnalytics() {
        let current = enableAnalytics
        UserDefaults.standard.set(!current, forKey: "enable_analytics")
    }
    
    var openAIAPIKey: String? {
        // Return user-configured key if exists
        if let userKey = UserDefaults.standard.string(forKey: "openai_api_key") {
            return userKey
        }
        // Try to load from config file
        return loadAPIKeyFromConfig()
    }
    
    private func loadAPIKeyFromConfig() -> String? {
        guard let configPath = Bundle.main.path(forResource: "config", ofType: "json") else {
            // Try to load from app directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let configURL = documentsPath?.appendingPathComponent("config.json")
            
            // Try current working directory for development
            let currentDirURL = URL(fileURLWithPath: "config.json")
            
            for url in [configURL, currentDirURL].compactMap({ $0 }) {
                if FileManager.default.fileExists(atPath: url.path) {
                    return loadConfigFromURL(url)
                }
            }
            return nil
        }
        
        let configURL = URL(fileURLWithPath: configPath)
        return loadConfigFromURL(configURL)
    }
    
    private func loadConfigFromURL(_ url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return config?["openai_api_key"] as? String
        } catch {
            print("Failed to load config: \(error)")
            return nil
        }
    }
    
    func setOpenAIAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }
    
    func clearOpenAIAPIKey() {
        UserDefaults.standard.removeObject(forKey: "openai_api_key")
    }
}

extension AppConfig {
    static var mock: AppConfig {
        AppConfig.shared
    }
}