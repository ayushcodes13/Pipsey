import AppKit
import SwiftUI
import PipseyCore

// MARK: - Tab Enum

public enum SettingsTab: String, CaseIterable, Identifiable, Sendable {
    case general
    case models
    case privacy
    case shortcuts
    case about

    public var id: Self { self }

    public var title: String {
        switch self {
        case .general: "General"
        case .models: "AI Models & BYOK"
        case .privacy: "Privacy & Permissions"
        case .shortcuts: "Shortcuts & Gestures"
        case .about: "About Pipsey"
        }
    }

    public var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .models: "cpu"
        case .privacy: "lock.shield"
        case .shortcuts: "command"
        case .about: "info.circle"
        }
    }
}

// MARK: - Navigation State

@MainActor
public final class SettingsNavigation: ObservableObject {
    public static let shared = SettingsNavigation()
    @Published public var selectedTab: SettingsTab? = .general
    private init() {}
}

// MARK: - Main Settings View

public struct SettingsView: View {
    @ObservedObject private var navigation = SettingsNavigation.shared
    @State private var navigationHistory: [SettingsTab] = [.general]
    @State private var historyIndex = 0
    @State private var isHistoryNavigation = false

    private var activeTab: SettingsTab {
        navigation.selectedTab ?? .general
    }

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(selection: $navigation.selectedTab) {
                Section("Settings") {
                    ForEach(SettingsTab.allCases) { tab in
                        Label(tab.title, systemImage: tab.systemImage)
                            .tag(tab)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(width: 210)
            .navigationSplitViewColumnWidth(min: 200, ideal: 210, max: 240)
            .removeSidebarToggleIfAvailable()
        } detail: {
            Group {
                switch activeTab {
                case .general:
                    GeneralSettingsPane()
                case .models:
                    ModelsSettingsPane()
                case .privacy:
                    PrivacySettingsPane()
                case .shortcuts:
                    ShortcutsSettingsPane()
                case .about:
                    AboutSettingsPane()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(activeTab.title)
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 680, minHeight: 520)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)

                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
            }
        }
        .onChange(of: navigation.selectedTab) { newTab in
            guard let newTab, !isHistoryNavigation else { return }
            if historyIndex < navigationHistory.count - 1 {
                navigationHistory.removeSubrange((historyIndex + 1)...)
            }
            navigationHistory.append(newTab)
            historyIndex = navigationHistory.count - 1
        }
    }

    private var canGoBack: Bool { historyIndex > 0 }
    private var canGoForward: Bool { historyIndex < navigationHistory.count - 1 }

    private func goBack() {
        guard canGoBack else { return }
        isHistoryNavigation = true
        historyIndex -= 1
        navigation.selectedTab = navigationHistory[historyIndex]
        DispatchQueue.main.async { isHistoryNavigation = false }
    }

    private func goForward() {
        guard canGoForward else { return }
        isHistoryNavigation = true
        historyIndex += 1
        navigation.selectedTab = navigationHistory[historyIndex]
        DispatchQueue.main.async { isHistoryNavigation = false }
    }
}

// MARK: - General Settings Pane

struct GeneralSettingsPane: View {
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @State private var showInDock: Bool = !UserDefaults.standard.bool(forKey: "pipsey_hide_dock_icon")
    @State private var companionStyle: String = UserDefaults.standard.string(forKey: "companionStyle") ?? CompanionStyle.notchIsland.rawValue
    @State private var companionAppearance: String = UserDefaults.standard.string(forKey: "companionAppearance") ?? "wisprCapsule"
    @State private var hideIdleCompanion: Bool = UserDefaults.standard.bool(forKey: "pipsey_hide_idle_companion")
    @State private var anchorCorner: String = UserDefaults.standard.string(forKey: "companionCorner") ?? CompanionCorner.topRight.rawValue
    @State private var idlePeekingEnabled: Bool = UserDefaults.standard.object(forKey: "pipsey_idle_peeking") as? Bool ?? true
    @State private var soundEffectsEnabled: Bool = UserDefaults.standard.object(forKey: "pipsey_sound_effects_enabled") as? Bool ?? true

    var body: some View {
        Form {
            Section("Companion Style & Placement") {
                Picker("Indicator Appearance", selection: $companionAppearance) {
                    Text("Aperture Jewel (Machined Optics)").tag("apertureJewel")
                    Text("Wispr Capsule (Aperture Pill)").tag("wisprCapsule")
                    Text("Precision Glass Lens").tag("precisionLens")
                    Text("Minimalist Cyber-Visor").tag("cyberVisor")
                    Text("Full Mascot Robot").tag("fullMascot")
                }
                .pickerStyle(.segmented)
                .onChange(of: companionAppearance) { newAppearance in
                    UserDefaults.standard.set(newAppearance, forKey: "companionAppearance")
                    NotificationCenter.default.post(name: Notification.Name("pipsey_appearance_changed"), object: nil)
                }

                Toggle("Hide Floating Indicator when Idle (Menu Bar Only)", isOn: $hideIdleCompanion)
                    .onChange(of: hideIdleCompanion) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "pipsey_hide_idle_companion")
                        NotificationCenter.default.post(name: Notification.Name("pipsey_hide_idle_changed"), object: nil)
                    }

                Picker("Companion Form Factor", selection: $companionStyle) {
                    Text("Floating Corner Circle (Desktop Robot)").tag(CompanionStyle.floatingCircle.rawValue)
                    Text("Screen Notch Island (Top Center)").tag(CompanionStyle.notchIsland.rawValue)
                }
                .pickerStyle(.segmented)
                .onChange(of: companionStyle) { newStyle in
                    UserDefaults.standard.set(newStyle, forKey: "companionStyle")
                    NotificationCenter.default.post(name: Notification.Name("pipsey_style_changed"), object: nil)
                    if let panel = NSApp.windows.first(where: { $0 is FloatingIslandPanel }) as? FloatingIslandPanel {
                        panel.companionStyle = CompanionStyle(rawValue: newStyle) ?? .floatingCircle
                        panel.resetToDefaultPosition()
                    }
                }

                if companionStyle == CompanionStyle.floatingCircle.rawValue {
                    Picker("Screen Anchor Corner", selection: $anchorCorner) {
                        Text("Top Right").tag(CompanionCorner.topRight.rawValue)
                        Text("Top Left").tag(CompanionCorner.topLeft.rawValue)
                        Text("Bottom Right").tag(CompanionCorner.bottomRight.rawValue)
                        Text("Bottom Left").tag(CompanionCorner.bottomLeft.rawValue)
                    }
                    .onChange(of: anchorCorner) { newCorner in
                        UserDefaults.standard.set(newCorner, forKey: "companionCorner")
                        if let panel = NSApp.windows.first(where: { $0 is FloatingIslandPanel }) as? FloatingIslandPanel {
                            panel.anchorCorner = CompanionCorner(rawValue: newCorner) ?? .topRight
                            panel.snapToCorner(panel.anchorCorner)
                        }
                    }

                    Toggle("30-Second Idle Curiosity Peeking", isOn: $idlePeekingEnabled)
                        .onChange(of: idlePeekingEnabled) { enabled in
                            UserDefaults.standard.set(enabled, forKey: "pipsey_idle_peeking")
                        }
                    Text("Pipsey gently peeks over the circular lip and looks left and right every 30 seconds when resting idle.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reposition Companion")
                            .font(.body).bold()
                        Text("Drag Pipsey anywhere on your screen. Throwing near any screen corner magnetically snaps it in place.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(companionStyle == CompanionStyle.floatingCircle.rawValue ? "Snap to Anchor Corner" : "Snap to Top Center") {
                        if let panel = NSApp.windows.first(where: { $0 is FloatingIslandPanel }) as? FloatingIslandPanel {
                            panel.resetToDefaultPosition()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("Inspection Shortcuts") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Telescope Inspection Mode")
                            .font(.body).bold()
                        Text("Hold ⌃⌥⌘ (Control + Option + Command) to trigger high-precision telescope visual radar inspection.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        KeyBadge("⌃", isAccent: false)
                        KeyBadge("⌥", isAccent: true)
                        KeyBadge("⌘", isAccent: true)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quick Voice Capture")
                            .font(.body).bold()
                        Text("Hold ⌥⌘ (Option + Command) to talk and demonstrate an interaction.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        KeyBadge("⌥", isAccent: true)
                        KeyBadge("⌘", isAccent: true)
                    }
                }
            }

            Section("Startup & Visibility") {
                Toggle("Launch Pipsey at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enable in
                        LaunchAtLogin.setEnabled(enable)
                    }
                Text("Automatically start Pipsey when your Mac turns on.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Toggle("Show Pipsey in Dock", isOn: $showInDock)
                    .onChange(of: showInDock) { show in
                        NSApp.setActivationPolicy(show ? .regular : .accessory)
                        UserDefaults.standard.set(!show, forKey: "pipsey_hide_dock_icon")
                    }
                Text("When enabled, Pipsey appears in your macOS Dock and App Switcher (⌘-Tab). When disabled, Pipsey lives purely in your Menu Bar.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Sound Effects & Tactile Feedback") {
                Toggle("Enable Sound Effects", isOn: $soundEffectsEnabled)
                    .onChange(of: soundEffectsEnabled) { enabled in
                        UserDefaults.standard.set(enabled, forKey: "pipsey_sound_effects_enabled")
                    }
                Text("Plays native macOS tactile audio chimes on capture start/stop, response completion, copy, and telescope inspection.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if soundEffectsEnabled {
                    Divider()

                    VStack(spacing: 8) {
                        soundPreviewRow(title: "Capture Started", soundName: "Tink", icon: "record.circle") {
                            PipseySoundEffects.playCaptureStarted()
                        }
                        soundPreviewRow(title: "Capture Stopped", soundName: "Pop", icon: "stop.circle") {
                            PipseySoundEffects.playCaptureStopped()
                        }
                        soundPreviewRow(title: "Explanation Ready", soundName: "Glass", icon: "sparkles") {
                            PipseySoundEffects.playResponseReady()
                        }
                        soundPreviewRow(title: "Copied to Clipboard", soundName: "Bottle", icon: "doc.on.doc") {
                            PipseySoundEffects.playCopyFeedback()
                        }
                        soundPreviewRow(title: "Telescope Inspection (⌃⌥⌘)", soundName: "Ping", icon: "scope") {
                            PipseySoundEffects.playTelescopeFocus()
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .settingsScrollMargins()
    }

    private func soundPreviewRow(title: String, soundName: String, icon: String, onPlay: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(title)
                .font(.body)
            Spacer()
            Text(soundName)
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Test") {
                onPlay()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

// MARK: - Models Settings Pane

struct ModelsSettingsPane: View {
    @State private var selectedProvider: String = UserDefaults.standard.string(forKey: "pipsey_provider") ?? "openai"
    @State private var vlmBaseURL: String = ""
    @State private var vlmModel: String = ""
    @State private var vlmApiKey: String = ""

    @State private var textBaseURL: String = ""
    @State private var textModel: String = ""
    @State private var textApiKey: String = ""

    @State private var isTesting: Bool = false
    @State private var testStatus: String? = nil

    var body: some View {
        Form {
            Section("AI Provider Selection") {
                Picker("Active Provider", selection: $selectedProvider) {
                    Text("Azure OpenAI").tag("azure")
                    Text("OpenAI Compatible").tag("openai")
                    Text("Anthropic Claude").tag("anthropic")
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedProvider) { newProvider in
                    reloadForProvider(newProvider)
                }
            }

            Section("1. Vision-Language Model (VLM)") {
                TextField("Base URL", text: $vlmBaseURL)
                TextField("Model Identifier", text: $vlmModel)
                SecureField("API Key (Stored in Keychain)", text: $vlmApiKey)
                Text("Analyzes sampled screen demonstration frames to detect UI changes and mechanisms.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("2. Conversational Model (LLM)") {
                TextField("Base URL", text: $textBaseURL)
                TextField("Model Identifier", text: $textModel)
                SecureField("API Key (Stored in Keychain)", text: $textApiKey)
                Text("Generates clean explanations and full implementation code without hallucination.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Interactive Demo (Zero-Config Testing)") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Simulate Live Feature Mode")
                            .font(.body).bold()
                        Text("Test Pipsey's entire interactive companion workflow, audio waveform, voice explanation, and code library without entering API keys.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Try Demo Simulation") {
                        NotificationCenter.default.post(name: NSNotification.Name("PipseyTriggerDemoSimulation"), object: nil)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section {
                HStack {
                    Button(action: { Task { await testConnection() } }) {
                        HStack(spacing: 4) {
                            if isTesting { ProgressView().controlSize(.small) }
                            Text("Test Connection")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isTesting)

                    Spacer()

                    Button("Save Configuration") {
                        saveConfiguration()
                    }
                    .buttonStyle(.bordered)
                }

                if let status = testStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(status.contains("✓") ? .green : .orange)
                        .padding(.vertical, 2)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .settingsScrollMargins()
        .onAppear { loadConfiguration() }
    }

    private func loadConfiguration() {
        let vlm = VLMConfiguration.loadDefault()
        vlmBaseURL = vlm.baseURL.absoluteString
        vlmModel = vlm.model
        vlmApiKey = vlm.apiKey

        let text = TextLLMConfiguration.loadDefault()
        textBaseURL = text.baseURL.absoluteString
        textModel = text.model
        textApiKey = text.apiKey
    }

    private func reloadForProvider(_ newProvider: String) {
        let textAccount = (newProvider == "anthropic") ? "pipsey-anthropic-key" : "pipsey-text-api-key"
        textApiKey = KeychainManager.shared.readSecret(account: textAccount) ?? ""
        if newProvider == "anthropic" {
            if textBaseURL.contains("api.openai.com") { textBaseURL = "https://api.anthropic.com/v1" }
            if textModel.contains("gpt-") { textModel = "claude-3-5-sonnet-20241022" }
        } else if newProvider == "openai" {
            if textBaseURL.contains("anthropic.com") { textBaseURL = "https://api.openai.com/v1" }
            if textModel.contains("claude") { textModel = "gpt-4o-mini" }
        }
    }

    private func saveConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(vlmBaseURL, forKey: "pipsey_vlm_base_url")
        defaults.set(vlmModel, forKey: "pipsey_vlm_model")
        defaults.set(textBaseURL, forKey: "pipsey_text_base_url")
        defaults.set(textModel, forKey: "pipsey_text_model")
        defaults.set(selectedProvider, forKey: "pipsey_provider")

        if !vlmApiKey.isEmpty {
            try? KeychainManager.shared.saveSecret(account: "pipsey-vlm-api-key", secret: vlmApiKey)
        }
        let textAccount = (selectedProvider == "anthropic") ? "pipsey-anthropic-key" : "pipsey-text-api-key"
        if !textApiKey.isEmpty {
            try? KeychainManager.shared.saveSecret(account: textAccount, secret: textApiKey)
        }
        testStatus = "✓ Configuration saved securely in Keychain."
    }

    private func testConnection() async {
        isTesting = true
        testStatus = "Testing VLM & LLM endpoint connections..."
        var messages: [String] = []

        // VLM Test
        let vlmConfig = VLMConfiguration(
            baseURL: URL(string: vlmBaseURL) ?? URL(string: "https://api.openai.com/v1")!,
            apiKey: vlmApiKey,
            model: vlmModel
        )
        let vlmClient = HostedVLMClient(config: vlmConfig)
        do {
            let dummyManifest = EvidenceManifest(
                sessionId: UUID(),
                generation: 1,
                capture: CaptureInfo(targetType: .display, targetId: "test", dimensions: Dimensions(width: 100, height: 100), startedAtMonotonicMs: 0, durationMs: 100, permissionState: "granted"),
                frames: [],
                events: [],
                transcripts: []
            )
            _ = try await vlmClient.observe(manifest: dummyManifest, frames: [])
            messages.append("✓ VLM (\(vlmConfig.model)): Verified")
        } catch ObserverError.unauthorized {
            messages.append("❌ VLM: Unauthorized (invalid API key)")
        } catch ObserverError.schemaValidationFailed {
            messages.append("✓ VLM (\(vlmConfig.model)): Connected & responsive")
        } catch {
            messages.append("⚠️ VLM: \(error.localizedDescription)")
        }

        // LLM Test
        let defaultTextBase = (selectedProvider == "anthropic") ? "https://api.anthropic.com/v1" : "https://api.openai.com/v1"
        let textConfig = TextLLMConfiguration(
            baseURL: URL(string: textBaseURL) ?? URL(string: defaultTextBase)!,
            apiKey: textApiKey,
            model: textModel
        )
        let convClient = HostedConversationClient(config: textConfig)
        do {
            _ = try await convClient.explain(
                question: "ping",
                observations: [Observation(id: "ping", startMs: 0, endMs: 100, before: "A", after: "B", evidenceFrameIds: ["f1"])],
                history: []
            )
            messages.append("✓ LLM (\(textConfig.model)): Verified")
        } catch ConversationError.unauthorized {
            messages.append("❌ LLM: Unauthorized (invalid API key)")
        } catch {
            messages.append("⚠️ LLM: \(error.localizedDescription)")
        }

        testStatus = messages.joined(separator: "\n")
        isTesting = false
    }
}

// MARK: - Privacy Settings Pane

struct PrivacySettingsPane: View {
    @State private var uploadConsent: Bool = UserDefaults.standard.object(forKey: "pipsey_upload_consent_granted") as? Bool ?? true
    @State private var snapshot = PermissionCoordinator.shared.currentSnapshot()

    var body: some View {
        Form {
            Section("Data Transmission Consent") {
                Toggle("Explicit Upload Consent", isOn: $uploadConsent)
                    .onChange(of: uploadConsent) { val in
                        UserDefaults.standard.set(val, forKey: "pipsey_upload_consent_granted")
                    }
                Text("Authorizes sending sampled UI frames to your configured VLM endpoint. Disabling this strictly blocks any outbound screen transmission.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("System Permissions") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Screen Recording")
                            .font(.body).bold()
                        Text("Captures operational frames only when explicitly recording.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    statusBadge(granted: snapshot.screenRecording == .granted)
                    if snapshot.screenRecording == .granted {
                        Button("Open System Settings") {
                            PermissionCoordinator.shared.openScreenRecordingSettings()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Allow / Open Settings") {
                            Task {
                                let verified = await PermissionCoordinator.shared.verifyScreenRecordingAccess()
                                if !verified {
                                    let requested = PermissionCoordinator.shared.requestScreenRecordingAccess()
                                    if !requested {
                                        PermissionCoordinator.shared.openScreenRecordingSettings()
                                    }
                                }
                                snapshot = PermissionCoordinator.shared.currentSnapshot()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                if snapshot.screenRecording != .granted {
                    HStack {
                        Text("macOS requires restarting Pipsey after toggling Screen Recording.")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Button("Restart Pipsey to Apply") {
                            let url = Bundle.main.bundleURL
                            let config = NSWorkspace.OpenConfiguration()
                            NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
                                DispatchQueue.main.async { NSApp.terminate(nil) }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Microphone")
                            .font(.body).bold()
                        Text("Listens to your verbal question during interaction demonstration.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    statusBadge(granted: snapshot.microphone == .authorized)
                    Button("Request Access") {
                        Task {
                            let granted = await PermissionCoordinator.shared.requestMicrophoneAccess()
                            let updated = PermissionCoordinator.shared.currentSnapshot()
                            snapshot = updated
                            if !granted && updated.microphone != .authorized {
                                PermissionCoordinator.shared.openMicrophoneSettings()
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Speech Recognition")
                            .font(.body).bold()
                        Text("Converts spoken questions into text locally on-device.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    statusBadge(granted: snapshot.speechRecognition == .authorized)
                    Button("Request Access") {
                        Task {
                            let granted = await PermissionCoordinator.shared.requestSpeechAccess()
                            let updated = PermissionCoordinator.shared.currentSnapshot()
                            snapshot = updated
                            if !granted && updated.speechRecognition != .authorized {
                                PermissionCoordinator.shared.openSpeechRecognitionSettings()
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .settingsScrollMargins()
    }

    private func statusBadge(granted: Bool) -> some View {
        HStack(spacing: 4) {
            Circle().fill(granted ? Color.green : Color.orange).frame(width: 8, height: 8)
            Text(granted ? "Granted" : "Required")
                .font(.caption)
                .foregroundColor(granted ? .green : .orange)
        }
    }
}

// MARK: - Shortcuts Settings Pane

struct ShortcutsSettingsPane: View {
    var body: some View {
        Form {
            Section("Global Shortcuts & Gestures") {
                LabeledContent("Hold-to-Record") {
                    ShortcutComboBadge(["⌥", "⌘"])
                }
                Text("Hold Option+Command anywhere to start recording your screen and voice. Releasing automatically finishes capture and begins analysis.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                LabeledContent("Toggle Recording Hotkey") {
                    ShortcutComboBadge(["⌥", "⌘", "P"])
                }
                Text("Press once to start recording; press again to finish.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                LabeledContent("Interaction Library") {
                    ShortcutComboBadge(["⌘", "H"])
                }
                Text("Quickly open your saved UI explanations, history, and exported code.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                LabeledContent("Open Settings") {
                    ShortcutComboBadge(["⌘", ","])
                }
                Text("Open this settings and AI configuration window.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .settingsScrollMargins()
    }
}

// MARK: - About Settings Pane

struct AboutSettingsPane: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            PipseyMascotView(size: 72)
            Text("Pipsey")
                .font(.system(size: 24, weight: .bold))
            Text("Native macOS Feature Mode Companion")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Version 0.1.0")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            Text("Made with ❤️ by Devayush")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "0A84FF"))

            Divider().frame(width: 300)

            VStack(alignment: .leading, spacing: 6) {
                Text("• ScreenCaptureKit hardware-accelerated capture")
                Text("• Two-model architecture: Small hosted VLM + Conversational LLM")
                Text("• Zero background recording — activates only on explicit user invocation")
                Text("• Local JSON Interaction Library with Markdown code export")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

// MARK: - Backward-Compatible Modifiers

extension View {
    @ViewBuilder
    func settingsScrollMargins() -> some View {
        if #available(macOS 14.0, *) {
            self.contentMargins(.top, 8, for: .scrollContent)
        } else {
            self.padding(.top, 8)
        }
    }

    @ViewBuilder
    func removeSidebarToggleIfAvailable() -> some View {
        if #available(macOS 14.0, *) {
            self.toolbar(removing: .sidebarToggle)
        } else {
            self
        }
    }
}
