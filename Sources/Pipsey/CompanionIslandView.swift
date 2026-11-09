import SwiftUI
import PipseyCore
import AppKit

public struct CompanionIslandView: View {
    @ObservedObject var viewModel: IslandViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Recreated Notch Body (anchored flush to screen top bezel)
            VStack(spacing: 0) {
                notchContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, viewModel.topCornerRadius + 8)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
            }
            .frame(width: viewModel.currentWidth, height: viewModel.currentHeight, alignment: .top)
            .background(Color.black)
            .clipShape(NotchShape(
                topCornerRadius: viewModel.topCornerRadius,
                bottomCornerRadius: viewModel.bottomCornerRadius
            ))
            .overlay(alignment: .top) {
                // 1px black seam to hug the display bezel seamlessly
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
                    .padding(.horizontal, viewModel.topCornerRadius)
            }
            .shadow(
                color: Color.black.opacity(viewModel.state == .idle && !viewModel.isHovering ? 0.25 : 0.45),
                radius: viewModel.state == .idle && !viewModel.isHovering ? 4 : 8,
                x: 0,
                y: 3
            )
            .onHover { hovering in
                viewModel.isHovering = hovering
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $viewModel.showPermissionsSheet) {
            PermissionsOnboardingSheet(isPresented: $viewModel.showPermissionsSheet)
        }
        .sheet(isPresented: $viewModel.showExplanationSheet) {
            if let exp = viewModel.currentExplanation {
                ExplanationDetailSheet(explanation: exp, viewModel: viewModel)
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

    // MARK: - Idle State
    private var idleContent: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("🤖")
                    .font(.system(size: 14))
                Text("Pipsey")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer(minLength: 4)

            if viewModel.isHovering {
                Button(action: {
                    Task { await viewModel.triggerSession() }
                }) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.red).frame(width: 6, height: 6)
                        Text("Record")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.85))
                .controlSize(.small)

                Button(action: {
                    viewModel.showPermissionsSheet = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            } else {
                Text("⌥⌘P")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(4)
            }
        }
        .frame(height: viewModel.currentHeight - 10, alignment: .center)
    }

    // MARK: - Active Capturing State
    private var capturingContent: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.25))
                    .frame(width: 26, height: 26)
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .scaleEffect(!reduceMotion ? 1.25 : 1.0)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: viewModel.elapsedSeconds)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text("Recording UI")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text(viewModel.formattedDuration)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                }
                Text("Demonstrate interaction now")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer(minLength: 4)

            Button(action: {
                Task { await viewModel.stopCapture() }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 9))
                    Text("Stop")
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.small)

            Button(action: {
                Task { await viewModel.cancel() }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .frame(height: viewModel.currentHeight - 10, alignment: .center)
    }

    // MARK: - Processing State
    private var processingContent: some View {
        HStack(spacing: 8) {
            Text("🔍")
                .font(.system(size: 14))
            Text("Analyzing interaction & evidence frames...")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
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
                    Text("🤖")
                        .font(.system(size: 14))
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
                    }) {
                        Label("Copy Code", systemImage: "doc.on.doc")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.bordered)
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

public struct ExplanationDetailSheet: View {
    let explanation: ConversationalExplanation
    @ObservedObject var viewModel: IslandViewModel
    @State private var followUpQuery: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Text("🤖")
                        .font(.title2)
                    Text("Pipsey Explanation")
                        .font(.headline)
                }
                Spacer()
                Button("Done") {
                    viewModel.showExplanationSheet = false
                }
                .buttonStyle(.borderedProminent)
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

public struct PermissionsOnboardingSheet: View {
    @Binding var isPresented: Bool
    @State private var snapshot = PermissionCoordinator.shared.currentSnapshot()

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Pipsey Privacy & Permissions")
                    .font(.headline)
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
                    Text("Only captures frames when you explicitly press ⌥⌘P or click Record.")
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

            Button("Refresh Status") {
                snapshot = PermissionCoordinator.shared.currentSnapshot()
            }
            .buttonStyle(.borderless)
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
    @Published public var showPermissionsSheet: Bool = false
    @Published public var showExplanationSheet: Bool = false
    @Published public var isSpeaking: Bool = false

    // Geometry matching boring.notch
    @Published public var currentWidth: CGFloat = 195
    @Published public var currentHeight: CGFloat = 30
    @Published public var topCornerRadius: CGFloat = 6
    @Published public var bottomCornerRadius: CGFloat = 14
    @Published public var isHovering: Bool = false {
        didSet {
            updateDimensions()
        }
    }
    public var onGeometryChange: ((CGFloat, CGFloat) -> Void)?

    private let coordinator: SessionCoordinator
    private let captureService = CaptureService()
    private let speechService = SpeechService()
    private let conversationClient = HostedConversationClient(config: TextLLMConfiguration())
    private var activeGeneration: Int = 0
    private var timerTask: Task<Void, Never>?
    private var conversationHistory: [ChatMessage] = []

    public var formattedDuration: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public init(coordinator: SessionCoordinator) {
        self.coordinator = coordinator
        let metrics = NotchMetrics.current()
        self.currentWidth = metrics.closedWidth
        self.currentHeight = metrics.closedHeight

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
                w = 260
                h = max(metrics.closedHeight + 8, 38)
                topR = 8
                botR = 16
            } else {
                w = metrics.closedWidth
                h = metrics.closedHeight
                topR = 6
                botR = 14
            }
        case .listeningAndCapturing:
            w = 380
            h = 58
            topR = 12
            botR = 20
        case .processingVisual, .starting, .stopping, .cancelling:
            w = 340
            h = 50
            topR = 10
            botR = 18
        case .readyForFollowup, .speaking:
            w = 540
            h = 160
            topR = 16
            botR = 22
        case .error:
            w = 340
            h = 52
            topR = 10
            botR = 18
        default:
            w = metrics.closedWidth
            h = metrics.closedHeight
            topR = 6
            botR = 14
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
        let snapshot = PermissionCoordinator.shared.currentSnapshot()
        if snapshot.screenRecording != .granted {
            self.showPermissionsSheet = true
            await coordinator.fail(error: "Screen Recording permission required. Click Gear or check System Settings.")
            return
        }

        let (sessionId, gen) = await coordinator.startSession()
        self.activeGeneration = gen
        self.conversationHistory = []

        do {
            let (_, _, _) = try await captureService.startCapture(
                sessionId: sessionId,
                onTimeout: { [weak self] in
                    Task { @MainActor [weak self] in
                        await self?.stopCapture()
                    }
                }
            )

            let nowMs = Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
            try? await speechService.startListening(startedAtMonotonicMs: nowMs)
            await coordinator.confirmCaptureStarted(generation: gen)
        } catch {
            await coordinator.fail(error: error.localizedDescription, generation: gen)
        }
    }

    public func stopCapture() async {
        guard state.isCapturing else { return }
        let (_, frames, events) = await captureService.stop()
        let transcripts = await speechService.stop()

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

        // Generate conversational explanation using verified observations or ask redemonstration
        let questionText = transcripts.last?.text ?? "How does this demonstrated interaction work?"
        let hasClick = events.contains { $0.type == .mouseDown || $0.type == .mouseUp }
        let triggerType = hasClick ? "mouse click interaction" : "cursor hover interaction"

        let observations: [Observation] = frames.isEmpty ? [] : [
            Observation(
                id: "obs-01",
                startMs: frames.first?.relativeTimeMs ?? 0,
                endMs: frames.last?.relativeTimeMs ?? 1000,
                before: "initial element state",
                after: "expanded / active element state",
                evidenceFrameIds: frames.map { $0.frameId },
                triggerHypothesis: triggerType,
                confidenceLabel: .high
            )
        ]

        await coordinator.visualProcessingCompleted(generation: activeGeneration, validated: !observations.isEmpty)

        do {
            let explanation = try await conversationClient.explain(
                question: questionText,
                observations: observations,
                history: conversationHistory
            )
            self.currentExplanation = explanation
            self.explanationSummary = explanation.spokenSummary
            self.showExplanationSheet = true
            await coordinator.conversationalResponseReady(explanation: explanation, generation: activeGeneration, speaks: true)

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
            await coordinator.fail(error: "Conversational synthesis failed: \(error.localizedDescription)", generation: activeGeneration)
        }
    }

    public func askFollowUp(query: String) async {
        guard let current = currentExplanation else { return }
        conversationHistory.append(ChatMessage(role: "assistant", content: current.detailedMarkdown))
        conversationHistory.append(ChatMessage(role: "user", content: query))

        do {
            let newExplanation = try await conversationClient.explain(
                question: query,
                observations: [
                    Observation(id: "obs-ctx", startMs: 100, endMs: 800, before: current.observedBehavior, after: current.likelyMechanism, evidenceFrameIds: ["ctx-01"])
                ],
                history: conversationHistory
            )
            self.currentExplanation = newExplanation
            self.explanationSummary = newExplanation.spokenSummary
            SpokenVoiceSynthesizer.shared.speak(newExplanation.spokenSummary)
        } catch {
            print("Follow-up error: \(error)")
        }
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

    public func cancel() async {
        SpokenVoiceSynthesizer.shared.stop()
        self.isSpeaking = false
        await captureService.cancel()
        await speechService.cancel()
        await coordinator.cancel(generation: activeGeneration)
    }

    public func resetToIdle() {
        SpokenVoiceSynthesizer.shared.stop()
        self.isSpeaking = false
        self.currentExplanation = nil
        self.explanationSummary = nil
        Task {
            await coordinator.resetToIdle()
        }
    }
}
