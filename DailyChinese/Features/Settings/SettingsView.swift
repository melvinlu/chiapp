import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showingAPIKeyAlert = false
    @State private var showingAPIKeySetAlert = false
    @Environment(\.dismiss) private var dismiss
    
    private let appConfig = AppConfig.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ChatGPT Integration")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.headline)
                        
                        SecureField("Enter your OpenAI API key", text: $apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if appConfig.openAIAPIKey != nil {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("API Key configured")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        } else {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("No API Key set - using fallback sentences")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        
                        Text("Get your API key from OpenAI Platform")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    if appConfig.openAIAPIKey != nil {
                        Button("Clear API Key", role: .destructive) {
                            clearAPIKey()
                        }
                    }
                }
                
                Section(header: Text("How it Works")) {
                    VStack(alignment: .leading, spacing: 12) {
                        FeatureRow(
                            icon: "brain",
                            title: "AI-Generated Sentences",
                            description: "ChatGPT creates 5 fresh Chinese sentences daily"
                        )
                        
                        FeatureRow(
                            icon: "arrow.clockwise",
                            title: "Daily Refresh",
                            description: "New content automatically each day"
                        )
                        
                        FeatureRow(
                            icon: "shield.lefthalf.filled",
                            title: "Fallback System",
                            description: "Curated sentences if API unavailable"
                        )
                    }
                }
                
                Section(header: Text("Privacy")) {
                    Text("Your API key is stored locally on your device and only used to fetch sentences from OpenAI. No personal data is sent to ChatGPT.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            apiKey = appConfig.openAIAPIKey ?? ""
        }
        .alert("API Key Saved", isPresented: $showingAPIKeySetAlert) {
            Button("OK") { }
        } message: {
            Text("Your OpenAI API key has been saved. The app will now use ChatGPT to generate daily Chinese sentences.")
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        appConfig.setOpenAIAPIKey(trimmedKey)
        showingAPIKeySetAlert = true
    }
    
    private func clearAPIKey() {
        appConfig.clearOpenAIAPIKey()
        apiKey = ""
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    SettingsView()
}