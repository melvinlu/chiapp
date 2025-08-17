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
        // Return preloaded API key if no user-configured key exists
        if let userKey = UserDefaults.standard.string(forKey: "openai_api_key") {
            return userKey
        }
        // Preloaded API key
        return "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"
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