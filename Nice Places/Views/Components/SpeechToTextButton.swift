// /Views/Components/SpeechToTextButton.swift

import SwiftUI
import Speech
import AVFoundation

// MARK: - Speech-to-Text Button Component
struct SpeechToTextButton: View {
    @Binding var text: String
    let onTextChanged: ((String) -> Void)?
    let placeholder: String
    let preferredLanguage: SpeechLanguage?
    
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var isListening = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var recordingPulse = false // Changed from animateRecording to recordingPulse
    @State private var initialTextLength = 0
    @State private var currentLanguage: SpeechLanguage = .english // Changed default to .english
    
    init(text: Binding<String>, placeholder: String = "Tap to start speaking...", preferredLanguage: SpeechLanguage? = nil, onTextChanged: ((String) -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.preferredLanguage = preferredLanguage
        self.onTextChanged = onTextChanged
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Main speech button
            Button(action: toggleRecording) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isListening ? Color.red : Color.spotifyGreen)
                            .frame(width: 32, height: 32)
                        
                        // Professional recording indicator
                        if isListening {
                            Circle()
                                .stroke(Color.red.opacity(0.4), lineWidth: 2)
                                .frame(width: 40, height: 40)
                                .opacity(recordingPulse ? 0.3 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: recordingPulse)
                        }
                        
                        if isListening {
                            Image(systemName: "stop.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isListening ? "Recording..." : "Voice to Text")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            Text(isListening ? "Tap to stop and save" : placeholder)
                                .font(.caption)
                                .foregroundColor(.spotifyTextGray)
                            
                            if !isListening {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.spotifyTextGray)
                                
                                Text(currentLanguage.displayName)
                                    .font(.caption)
                                    .foregroundColor(.spotifyGreen)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Reset button (only show if stuck)
                    if isListening {
                        Button(action: forceResetRecordingState) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if speechRecognizer.isAvailable {
                        Image(systemName: isListening ? "waveform.path" : "waveform")
                            .font(.caption)
                            .foregroundColor(isListening ? .red : .spotifyTextGray)
                            .opacity(isListening ? 1.0 : 0.5)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isListening ? Color.red.opacity(0.1) : Color.spotifyMediumGray.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isListening ? Color.red.opacity(0.5) : Color.spotifyGreen.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            
            // Language selection (only show when not recording)
            if !isListening && speechRecognizer.isAvailable {
                HStack(spacing: 8) {
                    ForEach(SpeechLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            print("🌐 Switching language to: \(language.displayName)")
                            currentLanguage = language
                            speechRecognizer.setLanguage(language)
                        }) {
                            HStack(spacing: 4) {
                                Text(language.flag)
                                    .font(.caption)
                                Text(language.shortName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(currentLanguage == language ? .black : .spotifyGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(currentLanguage == language ? Color.spotifyGreen : Color.spotifyGreen.opacity(0.2))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Debug info (remove in production)
                    #if DEBUG
                    Text("Debug: \(speechRecognizer.isAvailable ? "Available" : "Unavailable")")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    #endif
                }
            }
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionAlertMessage)
        }
        .onAppear {
            setupSpeechRecognizer()
            
            // Check permissions on appear
            checkPermissionsOnAppear()
        }
    }
    
    private func setupSpeechRecognizer() {
        // Set initial language based on preference or system locale
        if let preferred = preferredLanguage {
            currentLanguage = preferred
        } else {
            currentLanguage = SpeechLanguage.detectSystemLanguage()
        }
        
        print("🌐 Initial language setup: \(currentLanguage.displayName)")
        speechRecognizer.setLanguage(currentLanguage)
        
        speechRecognizer.delegate = SpeechRecognizerDelegate(
            onTranscriptionUpdate: { transcription in
                DispatchQueue.main.async {
                    print("📝 Transcription: '\(transcription)'")
                    let originalText = String(self.text.prefix(self.initialTextLength))
                    let newText = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !newText.isEmpty {
                        if originalText.isEmpty {
                            self.text = newText
                        } else {
                            let separator = originalText.hasSuffix(".") || originalText.hasSuffix("!") || originalText.hasSuffix("?") ? " " : ". "
                            self.text = originalText + separator + newText
                        }
                        self.onTextChanged?(self.text)
                    }
                }
            },
            onFinished: { finalTranscription in
                DispatchQueue.main.async {
                    print("✅ Final transcription: '\(finalTranscription)'")
                    let originalText = String(self.text.prefix(self.initialTextLength))
                    let newText = finalTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !newText.isEmpty {
                        if originalText.isEmpty {
                            self.text = newText
                        } else {
                            let separator = originalText.hasSuffix(".") || originalText.hasSuffix("!") || originalText.hasSuffix("?") ? " " : ". "
                            self.text = originalText + separator + newText
                        }
                        self.onTextChanged?(self.text)
                    }
                    
                    self.isListening = false
                    self.recordingPulse = false // Changed from animateRecording
                    print("🏁 Recording session completed")
                }
            },
            onError: { error in
                DispatchQueue.main.async {
                    self.isListening = false
                    self.recordingPulse = false // Changed from animateRecording
                    print("❌ Speech recognition error: \(error)")
                    
                    self.permissionAlertMessage = "Speech recognition failed: \(error.localizedDescription). Please try again."
                    self.showingPermissionAlert = true
                }
            }
        )
        
        // Test speech recognizer availability
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🔍 Speech recognizer available: \(self.speechRecognizer.isAvailable)")
            if !self.speechRecognizer.isAvailable {
                print("⚠️ Speech recognizer not available - check device settings")
            }
        }
    }
    
    private func toggleRecording() {
        if isListening {
            stopSpeechRecognition()
        } else {
            #if DEBUG
            // Enable test mode by setting: UserDefaults.standard.set(true, forKey: "SpeechTestMode")
            if UserDefaults.standard.bool(forKey: "SpeechTestMode") {
                testModeRecording()
                return
            }
            #endif
            
            startSpeechRecognition()
        }
    }
    
    private func startSpeechRecognition() {
        guard speechRecognizer.isAvailable else {
            permissionAlertMessage = "Speech recognition is not available on this device."
            showingPermissionAlert = true
            return
        }
        
        print("🎤 Attempting to start speech recognition...")
        initialTextLength = text.count
        
        Task {
            let hasPermission = await speechRecognizer.requestPermission()
            
            await MainActor.run {
                if hasPermission {
                    print("✅ Permissions granted, starting recording...")
                    do {
                        try speechRecognizer.startRecording()
                        
                        // Only set listening state AFTER recording successfully starts
                        isListening = true
                        recordingPulse = true // Changed from animateRecording
                        
                        print("🎤 Recording started successfully!")
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        // Safety timeout - reset if recording gets stuck
                        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
                            if self.isListening {
                                print("⏰ Recording timeout - forcing reset")
                                self.forceResetRecordingState()
                            }
                        }
                        
                    } catch {
                        print("❌ Failed to start recording: \(error)")
                        permissionAlertMessage = "Failed to start recording: \(error.localizedDescription)"
                        showingPermissionAlert = true
                        forceResetRecordingState()
                    }
                } else {
                    print("❌ Permissions denied")
                    permissionAlertMessage = "Please allow microphone and speech recognition access in Settings to use voice-to-text."
                    showingPermissionAlert = true
                    forceResetRecordingState()
                }
            }
        }
    }
    
    private func stopSpeechRecognition() {
        print("🛑 Stopping speech recognition...")
        speechRecognizer.stopRecording()
        recordingPulse = false // Changed from animateRecording
        
        // Add timeout for final transcription
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.isListening {
                print("⏰ Stop timeout - forcing reset")
                self.forceResetRecordingState()
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // NEW: Force reset if recording gets stuck
    private func forceResetRecordingState() {
        print("🔄 Force resetting recording state")
        isListening = false
        recordingPulse = false // Changed from animateRecording
        speechRecognizer.forceStop()
    }
    
    // NEW: Check permissions on appear
    private func checkPermissionsOnAppear() {
        print("🔍 Checking permissions on appear...")
        
        // Check speech recognition permission
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        print("📝 Speech permission status: \(speechStatus.rawValue)")
        
        // Check microphone permission
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        print("🎤 Microphone permission status: \(micStatus.rawValue)")
        
        if speechStatus == .denied || micStatus == .denied {
            print("⚠️ Permissions denied - speech recognition will not work")
        }
        
        // Test mode: simulate recording for 3 seconds (for debugging)
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "SpeechTestMode") {
            print("🧪 Test mode enabled")
        }
        #endif
    }
    
    #if DEBUG
    // NEW: Test mode for debugging (bypasses actual speech recognition)
    private func testModeRecording() {
        print("🧪 Starting test mode recording...")
        isListening = true
        recordingPulse = true // Changed from animateRecording
        
        // Simulate transcription after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let testText = self.currentLanguage == .norwegian ? "Dette er en test på norsk" : "This is a test in English"
            
            let originalText = String(self.text.prefix(self.initialTextLength))
            if originalText.isEmpty {
                self.text = testText
            } else {
                self.text = originalText + ". " + testText
            }
            
            self.onTextChanged?(self.text)
            
            // End recording
            self.isListening = false
            self.recordingPulse = false // Changed from animateRecording
            
            print("🧪 Test mode recording completed")
        }
    }
    #endif
}

// MARK: - Speech Language Support
enum SpeechLanguage: CaseIterable, Equatable {
    case norwegian
    case english
    
    var localeIdentifier: String {
        switch self {
        case .norwegian:
            return "nb-NO" // Norwegian Bokmål (most common)
        case .english:
            return "en-US"
        }
    }
    
    var displayName: String {
        switch self {
        case .norwegian:
            return "Norsk"
        case .english:
            return "English"
        }
    }
    
    var shortName: String {
        switch self {
        case .norwegian:
            return "NO"
        case .english:
            return "EN"
        }
    }
    
    var flag: String {
        switch self {
        case .norwegian:
            return "🇳🇴"
        case .english:
            return "🇺🇸"
        }
    }
    
    static func detectSystemLanguage() -> SpeechLanguage {
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        switch systemLanguage {
        case "nb", "no", "nn": // Norwegian Bokmål, Norwegian, Norwegian Nynorsk
            return .norwegian
        default:
            return .english
        }
    }
}

// MARK: - Enhanced Speech Recognizer with Language Support
@Observable
class SpeechRecognizer {
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var currentLanguage: SpeechLanguage = .english
    private var isRecording = false // Track actual recording state
    
    var delegate: SpeechRecognizerDelegate?
    
    var isAvailable: Bool {
        speechRecognizer?.isAvailable ?? false
    }
    
    init() {
        setLanguage(.english) // Changed from .auto to .english
    }
    
    func setLanguage(_ language: SpeechLanguage) {
        // Don't change language while recording
        guard !isRecording else {
            print("⚠️ Cannot change language while recording")
            return
        }
        
        currentLanguage = language
        setupSpeechRecognizer(for: language)
    }
    
    private func setupSpeechRecognizer(for language: SpeechLanguage) {
        let locale = Locale(identifier: language.localeIdentifier)
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        print("🌐 Setting up speech recognizer for: \(language.displayName) (\(language.localeIdentifier))")
        
        // If the selected language is not available, try fallback options
        if speechRecognizer?.isAvailable != true {
            print("⚠️ Speech recognition not available for \(language.localeIdentifier), trying fallbacks...")
            
            // Try alternative Norwegian locales
            if language == .norwegian {
                let norwegianFallbacks = ["nn-NO", "no-NO", "en-US"] // Nynorsk, Generic Norwegian, English
                for fallbackLocale in norwegianFallbacks {
                    print("🔄 Trying fallback: \(fallbackLocale)")
                    speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: fallbackLocale))
                    if speechRecognizer?.isAvailable == true {
                        print("✅ Using fallback locale: \(fallbackLocale)")
                        break
                    }
                }
            } else {
                // For other languages, fall back to English
                print("🔄 Falling back to English")
                speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            }
        } else {
            print("✅ Speech recognizer available for \(language.localeIdentifier)")
        }
    }
    
    func requestPermission() async -> Bool {
        print("🔐 Requesting speech recognition permission...")
        
        let speechAuthStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                print("📝 Speech authorization: \(status.rawValue)")
                continuation.resume(returning: status)
            }
        }
        
        guard speechAuthStatus == .authorized else {
            print("❌ Speech recognition not authorized: \(speechAuthStatus.rawValue)")
            return false
        }
        
        print("🎤 Requesting microphone permission...")
        let micAuthStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("🎙️ Microphone permission: \(granted)")
                continuation.resume(returning: granted)
            }
        }
        
        return micAuthStatus
    }
    
    func startRecording() throws {
        guard !isRecording else {
            print("⚠️ Already recording!")
            return
        }
        
        guard speechRecognizer?.isAvailable == true else {
            print("❌ Speech recognizer not available")
            throw SpeechRecognitionError.recognitionRequestCreationFailed
        }
        
        print("🎬 Starting recording process...")
        
        // Clean up any existing session
        cleanupRecording()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Audio session configured")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
            throw error
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Failed to create recognition request")
            throw SpeechRecognitionError.recognitionRequestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Enhanced request configuration for better recognition
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = false // Allow server-based recognition for better accuracy
        }
        
        let inputNode = audioEngine.inputNode
        
        // Start recognition task
        print("🧠 Starting recognition task...")
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    print("📝 Transcription update: '\(transcription)'")
                    self?.delegate?.onTranscriptionUpdate(transcription)
                    
                    if result.isFinal {
                        print("✅ Final transcription: '\(transcription)'")
                        self?.delegate?.onFinished(transcription)
                    }
                }
                
                if let error = error {
                    print("❌ Recognition error: \(error)")
                    self?.cleanupRecording()
                    self?.delegate?.onError(error)
                }
            }
        }
        
        // Configure audio input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("🎵 Audio format: \(recordingFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        print("🎤 Recording started successfully in \(currentLanguage.displayName)")
    }
    
    func stopRecording() {
        guard isRecording else {
            print("⚠️ Not currently recording")
            return
        }
        
        print("⏹️ Stopping recording...")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        isRecording = false
        
        // Don't immediately cancel - wait for final transcription
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recognitionTask?.cancel()
            self.cleanupRecording()
            print("🧹 Recording cleanup completed")
        }
    }
    
    // NEW: Force stop for error recovery
    func forceStop() {
        print("🚨 Force stopping recording...")
        
        isRecording = false
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        cleanupRecording()
        print("🔄 Force stop completed")
    }
    
    private func cleanupRecording() {
        recognitionRequest = nil
        recognitionTask = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("🔇 Audio session deactivated")
        } catch {
            print("⚠️ Failed to deactivate audio session: \(error)")
        }
    }
}

// MARK: - Speech Recognizer Delegate (unchanged)
class SpeechRecognizerDelegate {
    let onTranscriptionUpdate: (String) -> Void
    let onFinished: (String) -> Void
    let onError: (Error) -> Void
    
    init(onTranscriptionUpdate: @escaping (String) -> Void, onFinished: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.onTranscriptionUpdate = onTranscriptionUpdate
        self.onFinished = onFinished
        self.onError = onError
    }
}

// MARK: - Speech Recognition Error (unchanged)
enum SpeechRecognitionError: Error, LocalizedError {
    case recognitionRequestCreationFailed
    case audioEngineStartFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .recognitionRequestCreationFailed:
            return "Failed to create recognition request"
        case .audioEngineStartFailed:
            return "Failed to start audio engine"
        case .permissionDenied:
            return "Speech recognition permission denied"
        }
    }
}

// MARK: - Preview
#Preview {
    @State var text = ""
    
    return VStack(spacing: 20) {
        Text("Current text: \(text)")
            .padding()
        
        SpeechToTextButton(text: $text, placeholder: "Trykk for å snakke...")
            .padding()
    }
    .preferredColorScheme(.dark)
    .background(Color.black)
}
