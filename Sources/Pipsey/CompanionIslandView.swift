import SwiftUI
import PipseyCore
import AppKit

/// Pristine vector-derived icon-only mascot view (without wordmark)
public struct PipseyMascotView: View {
    public var size: CGFloat

    public init(size: CGFloat = 20) {
        self.size = size
    }

    public var body: some View {
        if let img = loadMascotImage() {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Text("🤖")
                .font(.system(size: size * 0.75))
        }
    }

    private func loadMascotImage() -> NSImage? {
        if let url = Bundle.main.url(forResource: "pipsey-mascot-128", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        let local = URL(fileURLWithPath: "Assets/pipsey-mascot-128.png")
        if FileManager.default.fileExists(atPath: local.path) {
            return NSImage(contentsOf: local)
        }
        return nil
    }
}

public enum ActiveSheet: Identifiable, Sendable {
    case permissions
    case settings
    case explanation

    public var id: Int {
        switch self {
        case .permissions: return 1
        case .settings: return 2
        case .explanation: return 3
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    @ViewBuilder
    func smoothWindowDrag() -> some View {
        if #available(macOS 15.0, *) {
            self.gesture(WindowDragGesture())
        } else {
            self
        }
    }
}

public struct CompanionIslandView: View {
    @ObservedObject var viewModel: IslandViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var hasCopiedCode: Bool = false

    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                notchContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, viewModel.hasPhysicalNotch ? (viewModel.topCornerRadius + 8) : (viewModel.state == .idle && !viewModel.isHovering ? 6 : 12))
                    .padding(.vertical, viewModel.state == .idle && !viewModel.isHovering ? 1 : 3)
            }
            .frame(width: viewModel.currentWidth, height: viewModel.currentHeight, alignment: .center)
            .background(
                Group {
                    if viewModel.hasPhysicalNotch {
                        Color.black
                            .clipShape(NotchShape(
                                topCornerRadius: viewModel.topCornerRadius,
                                bottomCornerRadius: viewModel.bottomCornerRadius
                            ))
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 1)
                                    .padding(.horizontal, viewModel.topCornerRadius)
                            }
                    } else {
                        if viewModel.state == .idle && !viewModel.isHovering {
                            // Minimal Sleek Line Pill with Crisp White Outline
                            Capsule()
                                .fill(Color.black.opacity(0.92))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.35), lineWidth: 1.0)
                                )
                        } else if viewModel.state.isCapturing {
                            // Capturing Capsule with Elegant White Outline
                            RoundedRectangle(cornerRadius: viewModel.bottomCornerRadius, style: .continuous)
                                .fill(Color.black.opacity(0.94))
                                .overlay(
                                    RoundedRectangle(cornerRadius: viewModel.bottomCornerRadius, style: .continuous)
                                        .stroke(Color.white.opacity(0.75), lineWidth: 1.2)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: viewModel.bottomCornerRadius, style: .continuous)
                                .fill(Color.black.opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: viewModel.bottomCornerRadius, style: .continuous)
                                        .stroke(Color.white.opacity(0.35), lineWidth: 1.0)
                                )
                        }
                    }
                }
            )
            .shadow(
                color: viewModel.state.isCapturing
                    ? Color.white.opacity(0.20)
                    : Color.black.opacity(0.45),
                radius: viewModel.state.isCapturing ? 10 : (viewModel.state == .idle && !viewModel.isHovering ? 6 : 8),
                x: 0,
                y: 2
            )
            .smoothWindowDrag()
            .onHover { hovering in
                viewModel.isHovering = hovering
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .permissions:
                PermissionsOnboardingSheet(isPresented: Binding(
                    get: { viewModel.activeSheet == .permissions },
                    set: { if !$0 { viewModel.activeSheet = nil } }
                ))
            case .settings:
                SettingsSheetView(
                    isPresented: Binding(
                        get: { viewModel.activeSheet == .settings },
                        set: { if !$0 { viewModel.activeSheet = nil } }
                    ),
                    viewModel: viewModel
                )
            case .explanation:
                if let exp = viewModel.currentExplanation {
                    ExplanationDetailSheet(explanation: exp, viewModel: viewModel)
                }
            }
        }
    }

    @ViewBuilder
    private var notchContent: some View {
        switch viewModel.state {
        case .idle:
            idleContent
        case .listeningAndCapturing:
            capturingContent
        case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling:
            processingContent
        case .readyForFollowup, .speaking:
            explanationContent
        case .error(let msg):
            errorContent(msg: msg)
        }
    }

    // MARK: - Idle State (White Outline with Neon Blue Center Line)
    @ViewBuilder
    private var idleContent: some View {
        if !viewModel.isHovering {
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0A84FF"),
                                Color(hex: "0071E3"),
                                Color(hex: "0A84FF")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 54, height: 3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                Task { await viewModel.triggerSession() }
            }
            .accessibilityLabel("Pipsey Companion (Hold ⌥⌘ to record, or drag to move)")
        } else {
            HStack(spacing: 8) {
                Button(action: {
                    Task { await viewModel.triggerSession() }
                }) {
                    PipseyMascotView(size: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pipsey Mascot (Click to record)")

                Spacer(minLength: 4)

                Button(action: {
                    Task { await viewModel.triggerSession() }
                }) {
                    HStack(spacing: 2) {
                        KeyBadge("⌥", isAccent: true)
                        KeyBadge("⌘", isAccent: true)
                    }
                }
                .buttonStyle(.plain)
                .help("Hold Option+Command to record interaction; tap to toggle")

                Button(action: {
                    SettingsWindowController.show()
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Pipsey Settings")

                Button(action: {
                    HistoryWindowController.shared.showHistory()
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Pipsey History")
            }
            .frame(height: viewModel.currentHeight - 6, alignment: .center)
        }
    }

    // MARK: - Active Capturing State (with live reactive audio waveform)
    private var capturingContent: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(!reduceMotion ? 1.25 : 1.0)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: viewModel.elapsedSeconds)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Recording UI")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(.white)

                    Text(viewModel.formattedDuration)
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))

                    // Live 5-bar reactive audio waveform
                    LiveWaveformView(audioPowerLevel: viewModel.audioPowerLevel)
                }

                Text("Listening... (Release ⌥⌘ to finish)")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer(minLength: 4)

            Button(action: {
                Task { await viewModel.stopCapture() }
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8.5, weight: .bold))
                    Text("Done")
                        .font(.system(size: 9.5, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Button(action: {
                Task { await viewModel.cancel() }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
        }
        .frame(height: viewModel.currentHeight - 6, alignment: .center)
    }

    // MARK: - Processing State
    private var processingContent: some View {
        HStack(spacing: 8) {
            PipseyMascotView(size: 18)
            Text(viewModel.processingStatusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
            Button(action: {
                Task { await viewModel.cancel() }
            }) {
                Text("Cancel")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .frame(height: viewModel.currentHeight - 10, alignment: .center)
    }

    // MARK: - Explanation State
    private var explanationContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    PipseyMascotView(size: 18)
                    Text("Interaction Explained")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {
                    viewModel.toggleSpeech()
                }) {
                    Image(systemName: viewModel.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: {
                    viewModel.resetToIdle()
                }) {
                    Text("Done")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text(viewModel.explanationSummary ?? "UI interaction analyzed.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.92))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button(action: {
                    viewModel.showExplanationSheet = true
                }) {
                    Label("View Full Code & Details", systemImage: "doc.text.magnifyingglass")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                if let code = viewModel.currentExplanation?.detailedMarkdown {
                    Button(action: {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(code, forType: .string)
                        PipseySoundEffects.playCopyFeedback()
                        hasCopiedCode = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            hasCopiedCode = false
                        }
                    }) {
                        Label(hasCopiedCode ? "Copied!" : "Copy Code", systemImage: hasCopiedCode ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
                    .tint(hasCopiedCode ? .green : .accentColor)
                    .controlSize(.small)
                }

                Spacer()
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Error State
    private func errorContent(msg: String) -> some View {
        HStack(spacing: 8) {
            Text("⚠️")
                .font(.system(size: 14))
            Text(msg)
                .font(.system(size: 11))
                .foregroundColor(.orange)
                .lineLimit(1)
            Spacer()
            Button(action: {
                Task { await viewModel.cancel() }
            }) {
                Text("Dismiss")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .frame(height: viewModel.currentHeight - 10, alignment: .center)
    }
}

/// A 5-bar live reactive audio waveform visualizer (in vibrant electric neon blue).
public struct LiveWaveformView: View {
    public let audioPowerLevel: CGFloat
    private let barCount = 5
    private let barProfile: [CGFloat] = [0.45, 0.75, 1.0, 0.75, 0.45]

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            HStack(alignment: .center, spacing: 2.2) {
                ForEach(0..<barCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(Color.white.opacity(0.85))
                        .frame(
                            width: 2.2,
                            height: barHeight(for: i, date: context.date)
                        )
                }
            }
            .animation(.linear(duration: 0.08), value: audioPowerLevel)
        }
    }

    private func barHeight(for index: Int, date: Date) -> CGFloat {
        let phase = CGFloat(date.timeIntervalSinceReferenceDate * 3.8) + CGFloat(index) * 0.35
        let normalizedPower = max(audioPowerLevel - 0.01, 0)
        let easedPower = pow(min(normalizedPower * 3.2, 1.0), 0.75)
        let reactiveHeight = easedPower * 13.0 * barProfile[index]
        let idlePulse = (sin(phase) + 1.0) / 2.0 * 2.2
        return max(3.0, 3.0 + reactiveHeight + idlePulse)
    }
}

public struct ExplanationDetailSheet: View {
    let explanation: ConversationalExplanation
    @ObservedObject var viewModel: IslandViewModel
    @State private var followUpQuery: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    PipseyMascotView(size: 26)
                    Text("Pipsey Explanation")
                        .font(.headline)
                }
                Spacer()
                Button("Done") {
                    viewModel.showExplanationSheet = false
                }
                .buttonStyle(.borderedProminent)
            }

            if let ctx = viewModel.activeAppContext {
                HStack(spacing: 6) {
                    Text(ctx.appName)
                        .font(.caption).bold()
                        .foregroundColor(Color(hex: "0A84FF"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "0A84FF").opacity(0.12))
                        .cornerRadius(4)

                    Text(ctx.suggestedFramework)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(4)

                    Spacer()

                    Button(action: {
                        HistoryWindowController.shared.showHistory()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("History (⌘H)")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        Text("Observed Behavior")
                            .font(.subheadline).bold()
                            .foregroundColor(.blue)
                        Text(explanation.observedBehavior)
                            .font(.body)

                        Divider()

                        Text("Likely Mechanism")
                            .font(.subheadline).bold()
                            .foregroundColor(.purple)
                        Text(explanation.likelyMechanism)
                            .font(.body)

                        Divider()

                        Text("Implementation Approach")
                            .font(.subheadline).bold()
                            .foregroundColor(.green)
                        Text(explanation.implementationApproach)
                            .font(.body)
                    }

                    if !explanation.detailedMarkdown.isEmpty {
                        Divider()
                        Text("Full Analysis & Implementation Code")
                            .font(.subheadline).bold()
                        Text(explanation.detailedMarkdown)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                            .cornerRadius(6)
                    }

                    if !explanation.uncertainties.isEmpty {
                        Divider()
                        Text("Uncertainties")
                            .font(.subheadline).bold()
                            .foregroundColor(.secondary)
                        ForEach(explanation.uncertainties, id: \.self) { u in
                            Text("• \(u)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 340)

            Divider()

            // Follow-up interaction
            HStack {
                TextField("Ask follow-up (e.g. 'How in React?')", text: $followUpQuery)
                    .textFieldStyle(.roundedBorder)

                Button("Ask") {
                    let q = followUpQuery
                    followUpQuery = ""
                    Task {
                        await viewModel.askFollowUp(query: q)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(followUpQuery.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 580)
    }
}

public struct SettingsSheetView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: IslandViewModel

    @State private var vlmBaseURL: String = ""
    @State private var vlmModel: String = ""
    @State private var vlmApiKey: String = ""

    @State private var textBaseURL: String = ""
    @State private var textModel: String = ""
    @State private var textApiKey: String = ""
    @State private var selectedProvider: String = "openai"
    @State private var uploadConsentGranted: Bool = true
    @State private var showInDock: Bool = true
    @State private var launchAtLogin: Bool = false

    @State private var testStatus: String? = nil
    @State private var isTesting: Bool = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    PipseyMascotView(size: 24)
                    Text("Pipsey Settings & AI Configuration")
                        .font(.headline)
                }
                Spacer()
                Button("Done") {
                    saveSettings()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }

            Text("Configure your Vision-Language Model (Model A) and Conversational LLM (Model B). Keys are saved securely in macOS Keychain and active clients reload immediately.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Provider selector
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active AI Provider")
                            .font(.subheadline).bold()
                        Picker("", selection: $selectedProvider) {
                            Text("Azure OpenAI").tag("azure")
                            Text("OpenAI Compatible").tag("openai")
                            Text("Anthropic Claude").tag("anthropic")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedProvider) { newProvider in
                            let textAccount = (newProvider == "anthropic") ? "pipsey-anthropic-key" : "pipsey-text-api-key"
                            textApiKey = KeychainManager.shared.readSecret(account: textAccount) ?? ""
                            if newProvider == "anthropic" {
                                if textBaseURL.contains("api.openai.com") {
                                    textBaseURL = "https://api.anthropic.com/v1"
                                }
                                if textModel.contains("gpt-") {
                                    textModel = "claude-3-5-sonnet-20241022"
                                }
                            } else if newProvider == "openai" {
                                if textBaseURL.contains("anthropic.com") {
                                    textBaseURL = "https://api.openai.com/v1"
                                }
                                if textModel.contains("claude") {
                                    textModel = "gpt-4o-mini"
                                }
                            }
                        }
                    }

                    Divider()

                    // Section 1: Vision Model
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1. Visual Observer Model (VLM)")
                            .font(.subheadline).bold()

                        TextField("VLM Base URL (e.g. https://api.openai.com/v1)", text: $vlmBaseURL)
                            .textFieldStyle(.roundedBorder)

                        TextField("Model Name (e.g. gpt-5-mini, gpt-4o-mini, qwen-vl-2b)", text: $vlmModel)
                            .textFieldStyle(.roundedBorder)

                        SecureField("VLM API Key", text: $vlmApiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Section 2: Conversational Model
                    VStack(alignment: .leading, spacing: 6) {
                        Text("2. Conversational LLM (Explanation & Chat)")
                            .font(.subheadline).bold()

                        TextField("LLM Base URL (e.g. https://api.openai.com/v1 or https://api.anthropic.com/v1)", text: $textBaseURL)
                            .textFieldStyle(.roundedBorder)

                        TextField("Model Name (e.g. gpt-5-mini, gpt-4o-mini, claude-3-5-sonnet)", text: $textModel)
                            .textFieldStyle(.roundedBorder)

                        SecureField("LLM API Key", text: $textApiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Upload Consent Toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Explicit Model Upload Consent", isOn: $uploadConsentGranted)
                            .font(.subheadline).bold()
                        Text("Allows sending recorded screen frames to your configured VLM endpoint for interaction analysis. Revoking this blocks external network uploads.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // macOS Dock Appearance
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Show Pipsey in Dock", isOn: $showInDock)
                            .font(.subheadline).bold()
                            .onChange(of: showInDock) { show in
                                NSApp.setActivationPolicy(show ? .regular : .accessory)
                                UserDefaults.standard.set(!show, forKey: "pipsey_hide_dock_icon")
                            }
                        Text("When enabled, Pipsey appears in your macOS Dock and App Switcher (⌘-Tab). When disabled, Pipsey lives purely in your Menu Bar and screen notch.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Launch at Login
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Launch Pipsey at Login", isOn: $launchAtLogin)
                            .font(.subheadline).bold()
                            .onChange(of: launchAtLogin) { enable in
                                LaunchAtLogin.setEnabled(enable)
                            }
                        Text("Automatically start Pipsey and anchor the companion island when your Mac starts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let status = testStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("✓") ? .green : .orange)
                            .padding(.vertical, 2)
                    }

                    HStack {
                        Button(action: {
                            Task { await testConnection() }
                        }) {
                            HStack(spacing: 4) {
                                if isTesting {
                                    ProgressView().controlSize(.small)
                                }
                                Text("Test Connection")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTesting)

                        Spacer()

                        Button("Clear Keychain Credentials") {
                            KeychainManager.shared.deleteSecret(account: "pipsey-vlm-api-key")
                            KeychainManager.shared.deleteSecret(account: "pipsey-text-api-key")
                            KeychainManager.shared.deleteSecret(account: "pipsey-anthropic-key")
                            vlmApiKey = ""
                            textApiKey = ""
                            testStatus = "Credentials cleared from Keychain."
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 340)
        }
        .padding(20)
        .frame(width: 520)
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        let vlm = VLMConfiguration.loadDefault()
        vlmBaseURL = defaults.string(forKey: "pipsey_vlm_base_url") ?? vlm.baseURL.absoluteString
        vlmModel = defaults.string(forKey: "pipsey_vlm_model") ?? vlm.model
        vlmApiKey = vlm.apiKey

        let text = TextLLMConfiguration.loadDefault()
        textBaseURL = defaults.string(forKey: "pipsey_text_base_url") ?? text.baseURL.absoluteString
        textModel = defaults.string(forKey: "pipsey_text_model") ?? text.model
        selectedProvider = defaults.string(forKey: "pipsey_provider") ?? (text.isAnthropic ? "anthropic" : (text.isAzure ? "azure" : "openai"))
        textApiKey = text.apiKey
        uploadConsentGranted = defaults.object(forKey: "pipsey_upload_consent_granted") as? Bool ?? true
        showInDock = !defaults.bool(forKey: "pipsey_hide_dock_icon")
        launchAtLogin = LaunchAtLogin.isEnabled
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(vlmBaseURL, forKey: "pipsey_vlm_base_url")
        defaults.set(vlmModel, forKey: "pipsey_vlm_model")
        defaults.set(textBaseURL, forKey: "pipsey_text_base_url")
        defaults.set(textModel, forKey: "pipsey_text_model")
        defaults.set(selectedProvider, forKey: "pipsey_provider")
        defaults.set(uploadConsentGranted, forKey: "pipsey_upload_consent_granted")
        defaults.set(!showInDock, forKey: "pipsey_hide_dock_icon")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
        LaunchAtLogin.setEnabled(launchAtLogin)

        if !vlmApiKey.isEmpty {
            try? KeychainManager.shared.saveSecret(account: "pipsey-vlm-api-key", secret: vlmApiKey)
        }
        let textAccount = (selectedProvider == "anthropic") ? "pipsey-anthropic-key" : "pipsey-text-api-key"
        if !textApiKey.isEmpty {
            try? KeychainManager.shared.saveSecret(account: textAccount, secret: textApiKey)
        }
        viewModel.reloadAIConfigurations()
    }

    private func testConnection() async {
        isTesting = true
        testStatus = "Testing VLM & LLM endpoint connections..."

        var messages: [String] = []

        // 1. Test VLM Endpoint
        let vlmConfig = VLMConfiguration(
            baseURL: URL(string: vlmBaseURL) ?? URL(string: "https://api.openai.com/v1")!,
            apiKey: vlmApiKey,
            model: vlmModel
        )
        let vlmClient = HostedVLMClient(config: vlmConfig)

        do {
            let start = DispatchTime.now()
            let dummyManifest = EvidenceManifest(
                sessionId: UUID(),
                generation: 1,
                capture: CaptureInfo(targetType: .display, targetId: "test", dimensions: Dimensions(width: 100, height: 100), startedAtMonotonicMs: 0, durationMs: 100, permissionState: "granted"),
                frames: [],
                events: [],
                transcripts: []
            )
            _ = try await vlmClient.observe(manifest: dummyManifest, frames: [])
            let elapsedMs = (DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            messages.append("✓ VLM (\(vlmConfig.model)): Verified (\(elapsedMs)ms)")
        } catch ObserverError.unauthorized {
            messages.append("❌ VLM: Unauthorized (invalid or missing API key)")
        } catch ObserverError.schemaValidationFailed {
            messages.append("✓ VLM (\(vlmConfig.model)): Connected & responsive")
        } catch {
            messages.append("⚠️ VLM: \(error.localizedDescription)")
        }

        // 2. Test Text LLM Endpoint
        let defaultTextBase = (selectedProvider == "anthropic") ? "https://api.anthropic.com/v1" : "https://api.openai.com/v1"
        let textConfig = TextLLMConfiguration(
            baseURL: URL(string: textBaseURL) ?? URL(string: defaultTextBase)!,
            apiKey: textApiKey,
            model: textModel
        )
        let convClient = HostedConversationClient(config: textConfig)

        do {
            let start = DispatchTime.now()
            _ = try await convClient.explain(
                question: "ping",
                observations: [
                    Observation(id: "ping", startMs: 0, endMs: 100, before: "A", after: "B", evidenceFrameIds: ["f1"])
                ],
                history: []
            )
            let elapsedMs = (DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            messages.append("✓ Text LLM (\(textConfig.model)): Verified (\(elapsedMs)ms)")
        } catch ConversationError.unauthorized {
            messages.append("❌ Text LLM: Unauthorized (invalid or missing API key)")
        } catch {
            messages.append("⚠️ Text LLM: \(error.localizedDescription)")
        }

        testStatus = messages.joined(separator: "\n")
        isTesting = false
    }
}

public struct PermissionsOnboardingSheet: View {
    @Binding var isPresented: Bool
    @State private var snapshot = PermissionCoordinator.shared.currentSnapshot()

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                HStack(spacing: 8) {
                    PipseyMascotView(size: 24)
                    Text("Pipsey Privacy & Permissions")
                        .font(.headline)
                }
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }

            Text("Pipsey requires standard macOS permissions for Screen Recording, Microphone, and Speech Recognition to observe and explain user-initiated UI demonstrations.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            // 1. Screen Recording
            HStack {
                VStack(alignment: .leading) {
                    Text("Screen Recording")
                        .font(.body).bold()
                    Text("Captures operational frames only when you explicitly press ⌥⌘P or click Record.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(for: snapshot.screenRecording == .granted)
                Button("System Settings") {
                    PermissionCoordinator.shared.openScreenRecordingSettings()
                }
                .buttonStyle(.bordered)
            }

            // 2. Microphone
            HStack {
                VStack(alignment: .leading) {
                    Text("Microphone")
                        .font(.body).bold()
                    Text("Listens to your question during the demonstration.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(for: snapshot.microphone == .authorized)
                Button("Request Access") {
                    Task {
                        _ = await PermissionCoordinator.shared.requestMicrophoneAccess()
                        if snapshot.microphone != .authorized {
                            PermissionCoordinator.shared.openMicrophoneSettings()
                        }
                        snapshot = PermissionCoordinator.shared.currentSnapshot()
                    }
                }
                .buttonStyle(.bordered)
            }

            // 3. Speech Recognition
            HStack {
                VStack(alignment: .leading) {
                    Text("Speech Recognition")
                        .font(.body).bold()
                    Text("Converts your verbal question into text locally.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(for: snapshot.speechRecognition == .authorized)
                Button("Request Access") {
                    Task {
                        _ = await PermissionCoordinator.shared.requestSpeechAccess()
                        if snapshot.speechRecognition != .authorized {
                            PermissionCoordinator.shared.openSpeechRecognitionSettings()
                        }
                        snapshot = PermissionCoordinator.shared.currentSnapshot()
                    }
                }
                .buttonStyle(.bordered)
            }

            Divider()

            HStack {
                Button("Refresh Status") {
                    snapshot = PermissionCoordinator.shared.currentSnapshot()
                }
                .buttonStyle(.borderless)

                Spacer()

                if snapshot.screenRecording != .granted {
                    Button("Restart Pipsey to Apply") {
                        let url = Bundle.main.bundleURL
                        let config = NSWorkspace.OpenConfiguration()
                        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
                            DispatchQueue.main.async {
                                NSApp.terminate(nil)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if snapshot.screenRecording != .granted {
                Text("Note: macOS TCC security requires restarting Pipsey after toggling Screen Recording in System Settings.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private func statusBadge(for granted: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(granted ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(granted ? "Granted" : "Required")
                .font(.caption)
                .foregroundColor(granted ? .green : .orange)
        }
    }
}

@MainActor
public final class IslandViewModel: ObservableObject {
    @Published public var state: SessionState = .idle
    @Published public var explanationSummary: String? = nil
    @Published public var currentExplanation: ConversationalExplanation? = nil
    @Published public var elapsedSeconds: Int = 0
    @Published public var initialQuestionInput: String = ""
    @Published public var activeAppContext: AppContext? = nil
    @Published public var activeSheet: ActiveSheet? = nil
    public var showPermissionsSheet: Bool {
        get { activeSheet == .permissions }
        set { activeSheet = newValue ? .permissions : (activeSheet == .permissions ? nil : activeSheet) }
    }
    public var showSettingsSheet: Bool {
        get { activeSheet == .settings }
        set { activeSheet = newValue ? .settings : (activeSheet == .settings ? nil : activeSheet) }
    }
    public var showExplanationSheet: Bool {
        get { activeSheet == .explanation }
        set { activeSheet = newValue ? .explanation : (activeSheet == .explanation ? nil : activeSheet) }
    }
    @Published public var isSpeaking: Bool = false
    @Published public var audioPowerLevel: CGFloat = 0.0
    @Published public var processingStatusText: String = "Analyzing interaction & evidence..." {
        didSet {
            updateDimensions()
        }
    }

    // Geometry matching boring.notch or Dynamic Island
    public let hasPhysicalNotch: Bool
    @Published public var currentWidth: CGFloat = 180
    @Published public var currentHeight: CGFloat = 32
    @Published public var topCornerRadius: CGFloat = 16
    @Published public var bottomCornerRadius: CGFloat = 16
    @Published public var isHovering: Bool = false {
        didSet {
            updateDimensions()
        }
    }

    public var onGeometryChange: ((CGFloat, CGFloat) -> Void)?
    public var onKeyWindowPermissionChange: ((Bool) -> Void)?
    public var onDragStart: (() -> Void)?
    public var onDragChanged: ((CGSize) -> Void)?
    public var onDragEnded: (() -> Void)?

    private let coordinator: SessionCoordinator
    private let captureService = CaptureService()
    private let speechService = SpeechService()
    private var vlmClient = HostedVLMClient()
    private var conversationClient = HostedConversationClient()
    private var activeGeneration: Int = 0
    private var activeSessionId: UUID = UUID()
    private var timerTask: Task<Void, Never>?
    private var activeInferenceTask: Task<Void, Never>?
    private var conversationHistory: [ChatMessage] = []

    public var formattedDuration: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public func reloadAIConfigurations() {
        self.vlmClient = HostedVLMClient(config: .loadDefault())
        self.conversationClient = HostedConversationClient(config: .loadDefault())
    }

    public init(coordinator: SessionCoordinator) {
        self.coordinator = coordinator
        let metrics = NotchMetrics.current()
        self.hasPhysicalNotch = metrics.hasPhysicalNotch
        self.currentWidth = metrics.closedWidth
        self.currentHeight = metrics.closedHeight
        self.topCornerRadius = metrics.hasPhysicalNotch ? 6 : 16
        self.bottomCornerRadius = metrics.hasPhysicalNotch ? 14 : 16

        Task {
            await coordinator.addStateChangeHandler { [weak self] newState in
                Task { @MainActor [weak self] in
                    self?.handleStateChange(newState)
                }
            }
        }
    }

    public func updateDimensions() {
        let metrics = NotchMetrics.current()
        let w: CGFloat
        let h: CGFloat
        let topR: CGFloat
        let botR: CGFloat

        switch state {
        case .idle:
            if isHovering {
                w = 175
                h = 32
                topR = hasPhysicalNotch ? 8 : 16
                botR = 16
            } else {
                w = hasPhysicalNotch ? metrics.closedWidth : 130
                h = hasPhysicalNotch ? metrics.closedHeight : 14
                topR = hasPhysicalNotch ? 6 : 7
                botR = hasPhysicalNotch ? 14 : 7
            }
        case .listeningAndCapturing:
            // Generous width for "Recording UI", live timer, 5-bar waveform, prompt, Done & Cancel
            w = 380
            h = 52
            topR = hasPhysicalNotch ? 12 : 18
            botR = 18
        case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling:
            // Dynamically expand notch width based on status text so it never clips
            let textLen = processingStatusText.count
            let dynamicW = CGFloat(textLen * 8) + 120
            w = min(560, max(380, dynamicW))
            h = 46
            topR = hasPhysicalNotch ? 10 : 18
            botR = 18
        case .readyForFollowup, .speaking:
            // Spaciously formatted explanation pane
            w = 520
            h = 160
            topR = hasPhysicalNotch ? 16 : 20
            botR = 20
        case .error(let msg):
            // Dynamically expand notch width so error messages are fully readable
            let dynamicW = CGFloat(msg.count * 8) + 120
            w = min(560, max(380, dynamicW))
            h = 50
            topR = hasPhysicalNotch ? 10 : 18
            botR = 18
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            self.topCornerRadius = topR
            self.bottomCornerRadius = botR
            self.currentWidth = w
            self.currentHeight = h
        }
        self.onGeometryChange?(w, h)
    }

    private func handleStateChange(_ newState: SessionState) {
        self.state = newState
        updateDimensions()

        // Enable key window input when user needs to interact with text fields in sheets
        let sheetActive = showExplanationSheet || showPermissionsSheet || showSettingsSheet
        onKeyWindowPermissionChange?(sheetActive)

        if newState == .listeningAndCapturing {
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        elapsedSeconds = 0
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                self?.elapsedSeconds += 1
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    public func triggerSession() async {
        if state.isCapturing {
            // Toggling shortcut or record while capturing cleanly stops demonstration
            await stopCapture()
            return
        }

        let snapshot = PermissionCoordinator.shared.currentSnapshot()
        if snapshot.screenRecording != .granted {
            self.showPermissionsSheet = true
            await coordinator.fail(error: "Screen Recording permission required. Click Gear or check System Settings.")
            return
        }

        let (sessionId, gen) = await coordinator.startSession()
        self.activeGeneration = gen
        self.activeSessionId = sessionId
        self.conversationHistory = []
        self.activeAppContext = AppContextProvider.shared.detectActiveContext()

        do {
            let (_, _, _) = try await captureService.startCapture(
                sessionId: sessionId,
                onTimeout: { [weak self] in
                    Task { @MainActor [weak self] in
                        await self?.stopCapture()
                    }
                }
            )

            // Setup real-time audio power callback for live waveform
            await speechService.setAudioPowerHandler { [weak self] power in
                Task { @MainActor [weak self] in
                    self?.audioPowerLevel = CGFloat(power)
                }
            }

            let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
            try? await speechService.startListening(startedAtMonotonicMs: nowMs)
            await coordinator.confirmCaptureStarted(generation: gen)

            // Tactile audio chime on start
            PipseySoundEffects.playCaptureStarted()
        } catch {
            await coordinator.fail(error: error.localizedDescription, generation: gen)
        }
    }

    public func stopCapture() async {
        guard state.isCapturing else { return }

        // Tactile audio chime on stop
        PipseySoundEffects.playCaptureStopped()

        let (durationMs, frames, events) = await captureService.stop()
        let transcripts = await speechService.stop()
        self.audioPowerLevel = 0.0

        for f in frames {
            await coordinator.appendFrame(metadata: f, generation: activeGeneration)
        }
        for e in events {
            await coordinator.appendEvent(metadata: e, generation: activeGeneration)
        }
        for t in transcripts {
            await coordinator.appendTranscript(text: t.text, isFinal: t.isFinal, generation: activeGeneration)
        }

        await coordinator.stopCapture(generation: activeGeneration)
        await coordinator.beginVisualProcessing(generation: activeGeneration)

        // Truthful check: if zero frames were captured, fail honestly rather than fabricating observations
        if frames.isEmpty {
            await coordinator.fail(
                error: "No video frames were captured during this recording. Please verify Screen Recording permissions in System Settings.",
                generation: activeGeneration
            )
            await captureService.cleanup()
            return
        }

        // Build genuine EvidenceManifest
        let manifest = EvidenceManifest(
            sessionId: activeSessionId,
            generation: activeGeneration,
            capture: CaptureInfo(
                targetType: .display,
                targetId: "main",
                dimensions: Dimensions(width: frames.first?.width ?? 1440, height: frames.first?.height ?? 900),
                startedAtMonotonicMs: 0,
                durationMs: durationMs,
                permissionState: "granted"
            ),
            frames: frames,
            events: events,
            transcripts: transcripts
        )

        let currentGen = activeGeneration
        activeInferenceTask?.cancel()
        activeInferenceTask = Task { [weak self] in
            guard let self = self else { return }
            guard !Task.isCancelled, self.activeGeneration == currentGen else { return }

            // Load actual sampled frames with image payloads
            let sampledFrames = await self.captureService.sampler?.loadSampledFrames() ?? []

            // Clean up session files from disk immediately after reading into memory
            await self.captureService.cleanup()

            // Pass real frames to VLM Observer
            self.processingStatusText = "Analyzing real screen frames with VLM..."

            // Explicit Model Upload Consent Gate: prevent unauthorized transmission of recorded screens
            let consentGranted = UserDefaults.standard.object(forKey: "pipsey_upload_consent_granted") as? Bool ?? true
            guard consentGranted else {
                await self.coordinator.fail(
                    error: "Screen frame upload blocked: Explicit model upload consent is disabled in Pipsey Settings.",
                    generation: currentGen
                )
                return
            }

            var observations: [Observation] = []
            do {
                let vlmResponse = try await self.vlmClient.observe(manifest: manifest, frames: sampledFrames)
                guard !Task.isCancelled, self.activeGeneration == currentGen else { return }
                observations = vlmResponse.observations

                guard !observations.isEmpty else {
                    await self.coordinator.fail(
                        error: "No UI transition was detected in the captured frames. Try demonstrating the action more clearly.",
                        generation: currentGen
                    )
                    return
                }

                await self.coordinator.visualProcessingCompleted(generation: currentGen, validated: true)
            } catch {
                guard !Task.isCancelled, self.activeGeneration == currentGen else { return }
                print("VLM pipeline failure: \(error)")
                await self.coordinator.fail(
                    error: "Visual inference failed: \(error.localizedDescription)",
                    generation: currentGen
                )
                return
            }

            guard !Task.isCancelled, self.activeGeneration == currentGen else { return }
            let spokenText = transcripts.last?.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let typedText = self.initialQuestionInput.trimmingCharacters(in: .whitespacesAndNewlines)
            let questionText = (!typedText.isEmpty) ? typedText : (spokenText?.isEmpty == false ? spokenText! : "How does this demonstrated interaction work?")
            self.processingStatusText = "Formulating explanation from verified observations..."

            do {
                let explanation = try await self.conversationClient.explain(
                    question: questionText,
                    observations: observations,
                    history: self.conversationHistory
                )

                guard !Task.isCancelled, self.activeGeneration == currentGen else { return }

                self.currentExplanation = explanation
                self.explanationSummary = explanation.spokenSummary
                self.showExplanationSheet = true
                await self.coordinator.conversationalResponseReady(explanation: explanation, generation: currentGen, speaks: true)

                // Persist interaction to local searchable session history
                let ctx = self.activeAppContext
                let record = SavedSessionRecord(
                    appName: ctx?.appName ?? "Active App",
                    appCategory: ctx?.category ?? "General UI",
                    suggestedFramework: ctx?.suggestedFramework ?? "React / SwiftUI",
                    question: questionText,
                    spokenSummary: explanation.spokenSummary,
                    likelyMechanism: explanation.likelyMechanism,
                    implementationApproach: explanation.implementationApproach,
                    detailedMarkdown: explanation.detailedMarkdown,
                    frameCount: frames.count,
                    durationMs: durationMs
                )
                Task {
                    await SessionHistoryManager.shared.save(record: record)
                }

                // Tactile audio chime when response is ready
                PipseySoundEffects.playResponseReady()

                // Trigger spoken response
                SpokenVoiceSynthesizer.shared.speak(explanation.spokenSummary) { [weak self] in
                    Task { @MainActor [weak self] in
                        self?.isSpeaking = false
                        if let gen = self?.activeGeneration {
                            await self?.coordinator.finishSpeaking(generation: gen)
                        }
                    }
                }
                self.isSpeaking = true
            } catch {
                guard !Task.isCancelled, self.activeGeneration == currentGen else { return }
                await self.coordinator.fail(
                    error: "Conversational synthesis failed: \(error.localizedDescription)",
                    generation: currentGen
                )
            }
        }
    }

    public func askFollowUp(query: String) async {
        guard let current = currentExplanation else { return }
        let currentGen = self.activeGeneration
        activeInferenceTask?.cancel()

        let task = Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.conversationHistory.append(ChatMessage(role: "assistant", content: current.detailedMarkdown))
            self.conversationHistory.append(ChatMessage(role: "user", content: query))

            do {
                let newExplanation = try await self.conversationClient.explain(
                    question: query,
                    observations: [
                        Observation(id: "obs-ctx", startMs: 100, endMs: 800, before: current.observedBehavior, after: current.likelyMechanism, evidenceFrameIds: ["ctx-01"])
                    ],
                    history: self.conversationHistory
                )
                guard !Task.isCancelled, self.activeGeneration == currentGen else { return }
                self.currentExplanation = newExplanation
                self.explanationSummary = newExplanation.spokenSummary
                SpokenVoiceSynthesizer.shared.speak(newExplanation.spokenSummary)
            } catch {
                guard !Task.isCancelled, self.activeGeneration == currentGen else { return }
                print("Follow-up error: \(error)")
            }
        }
        self.activeInferenceTask = task
        _ = await task.value
    }

    public func toggleSpeech() {
        if SpokenVoiceSynthesizer.shared.isSpeaking {
            SpokenVoiceSynthesizer.shared.stop()
            self.isSpeaking = false
        } else if let summary = explanationSummary {
            SpokenVoiceSynthesizer.shared.speak(summary) { [weak self] in
                Task { @MainActor in
                    self?.isSpeaking = false
                }
            }
            self.isSpeaking = true
        }
    }

    public func runDemoSimulation(scenario: DemoScenario = .springButton) async {
        await cancel()
        let (sessionId, gen) = await coordinator.startSession()
        self.activeGeneration = gen
        self.activeSessionId = sessionId
        self.activeAppContext = AppContext(
            appName: scenario.appName,
            bundleIdentifier: "com.figma.Desktop",
            category: scenario.appCategory,
            suggestedFramework: scenario.suggestedFramework
        )
        self.isHovering = true
        self.processingStatusText = "Simulating demonstration: '\(scenario.question)'"
        await coordinator.confirmCaptureStarted(generation: gen)
        PipseySoundEffects.playCaptureStarted()

        // 1. Simulate 2s of recording with realistic audio waveform bouncing
        for _ in 1...10 {
            try? await Task.sleep(nanoseconds: 200_000_000)
            self.audioPowerLevel = CGFloat.random(in: 0.35...0.90)
        }
        self.audioPowerLevel = 0.0
        PipseySoundEffects.playCaptureStopped()

        // 2. Transition to visual processing
        await coordinator.beginVisualProcessing(generation: gen)
        self.processingStatusText = "Analyzing demonstrated frames with VLM..."
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await coordinator.visualProcessingCompleted(generation: gen, validated: true)

        // 3. Transition to conversational response
        self.processingStatusText = "Formulating explanation..."
        try? await Task.sleep(nanoseconds: 800_000_000)

        let explanation = ConversationalExplanation(
            observedBehavior: "The user interacted with the UI component. On hover, the button scales up slightly, and on press it depresses with fluid spring damping before releasing with subtle overshoot.",
            likelyMechanism: scenario.likelyMechanism,
            implementationApproach: scenario.implementationApproach,
            uncertainties: [],
            spokenSummary: scenario.spokenSummary,
            detailedMarkdown: scenario.detailedMarkdown
        )

        self.currentExplanation = explanation
        self.explanationSummary = explanation.spokenSummary
        self.showExplanationSheet = true
        await coordinator.conversationalResponseReady(explanation: explanation, generation: gen, speaks: true)

        // Save to History
        let record = SavedSessionRecord(
            appName: scenario.appName,
            appCategory: scenario.appCategory,
            suggestedFramework: scenario.suggestedFramework,
            question: scenario.question,
            spokenSummary: scenario.spokenSummary,
            likelyMechanism: scenario.likelyMechanism,
            implementationApproach: scenario.implementationApproach,
            detailedMarkdown: scenario.detailedMarkdown,
            frameCount: scenario.frameCount,
            durationMs: scenario.durationMs
        )
        Task {
            await SessionHistoryManager.shared.save(record: record)
        }

        PipseySoundEffects.playResponseReady()

        // Spoken audio synthesis
        SpokenVoiceSynthesizer.shared.speak(scenario.spokenSummary) { [weak self] in
            Task { @MainActor [weak self] in
                self?.isSpeaking = false
                await self?.coordinator.finishSpeaking(generation: gen)
            }
        }
        self.isSpeaking = true
    }

    public func cancel() async {
        activeInferenceTask?.cancel()
        activeInferenceTask = nil
        SpokenVoiceSynthesizer.shared.stop()
        self.isSpeaking = false
        self.audioPowerLevel = 0.0
        await captureService.cancel()
        await speechService.cancel()
        await coordinator.cancel(generation: activeGeneration)
    }

    public func resetToIdle() {
        activeInferenceTask?.cancel()
        activeInferenceTask = nil
        SpokenVoiceSynthesizer.shared.stop()
        self.isSpeaking = false
        self.audioPowerLevel = 0.0
        self.currentExplanation = nil
        self.explanationSummary = nil
        Task {
            await captureService.cleanup()
            await coordinator.resetToIdle()
        }
    }
}
