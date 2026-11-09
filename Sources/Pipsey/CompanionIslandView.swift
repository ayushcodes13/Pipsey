import SwiftUI
import PipseyCore

public struct CompanionIslandView: View {
    @ObservedObject var viewModel: IslandViewModel
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var showPermissionsSheet: Bool = false

    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Mascot Avatar
            ZStack {
                Circle()
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle().stroke(mascotBorderColor, lineWidth: 2)
                    )

                Text(mascotEmoji)
                    .font(.system(size: 20))
                    .scaleEffect(viewModel.state.isCapturing && !reduceMotion ? 1.08 : 1.0)
                    .animation(reduceMotion ? .none : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.state.isCapturing)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pipsey status: \(statusTitle)")

            // Main Status & Timer
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(statusTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    if viewModel.state.isCapturing {
                        Text(viewModel.formattedDuration)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }

                Text(statusSubtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Dynamic Action Buttons
            HStack(spacing: 8) {
                if viewModel.state.isCapturing {
                    Button(action: {
                        Task { await viewModel.stopCapture() }
                    }) {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityLabel("Stop recording interaction")
                }

                if viewModel.state.canCancel {
                    Button(action: {
                        Task { await viewModel.cancel() }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Cancel current session")
                } else if viewModel.state == .idle {
                    Button(action: {
                        Task { await viewModel.triggerSession() }
                    }) {
                        Label("Observe", systemImage: "record.circle")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Activate observation mode")

                    Button(action: {
                        showPermissionsSheet = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Open privacy and permissions settings")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showPermissionsSheet) {
            PermissionsOnboardingSheet(isPresented: $showPermissionsSheet)
        }
    }

    private var mascotBorderColor: Color {
        switch viewModel.state {
        case .listeningAndCapturing: return .red
        case .processingVisual, .generatingResponse: return .blue
        case .speaking, .readyForFollowup: return .green
        case .error: return .orange
        default: return .gray.opacity(0.3)
        }
    }

    private var mascotEmoji: String {
        switch viewModel.state {
        case .listeningAndCapturing: return "🔴"
        case .processingVisual: return "🔍"
        case .generatingResponse: return "💭"
        case .speaking: return "🔊"
        case .readyForFollowup: return "🤖"
        case .error: return "⚠️"
        default: return "🤖"
        }
    }

    private var statusTitle: String {
        switch viewModel.state {
        case .idle: return "Pipsey"
        case .starting: return "Starting Capture..."
        case .listeningAndCapturing: return "Recording Interaction"
        case .stopping: return "Finishing Capture..."
        case .processingVisual: return "Analyzing Visuals..."
        case .generatingResponse: return "Formulating Answer..."
        case .speaking: return "Pipsey Speaking"
        case .readyForFollowup: return "Interaction Understood"
        case .cancelling: return "Cancelling..."
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private var statusSubtitle: String {
        switch viewModel.state {
        case .idle: return "Press ⌥⌘P or click Observe"
        case .listeningAndCapturing: return "Demonstrate UI transition now"
        case .processingVisual: return "Extracting frame-level evidence"
        case .generatingResponse: return "Synthesizing explanation"
        case .readyForFollowup, .speaking:
            return viewModel.explanationSummary ?? "Ask a follow-up anytime"
        case .error: return "Click Cancel to reset"
        default: return "Please wait..."
        }
    }
}

public struct PermissionsOnboardingSheet: View {
    @Binding var isPresented: Bool
    @State private var snapshot = PermissionCoordinator.shared.currentSnapshot()

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pipsey Permissions Onboarding")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }

            Text("Pipsey requires Screen Recording and Microphone access to observe UI demonstrations when you activate it. Recording is never continuous and stops when you say.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            // 1. Screen Recording
            HStack {
                VStack(alignment: .leading) {
                    Text("Screen Recording")
                        .font(.body).bold()
                    Text("Required to capture demonstrated interaction frames.")
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
                    Text("Required to hear verbal questions during capture.")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(for: snapshot.microphone == .authorized)
                Button("System Settings") {
                    PermissionCoordinator.shared.openMicrophoneSettings()
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
                Button("System Settings") {
                    PermissionCoordinator.shared.openSpeechRecognitionSettings()
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
    @Published public var elapsedSeconds: Int = 0

    private let coordinator: SessionCoordinator
    private var activeGeneration: Int = 0
    private var timerTask: Task<Void, Never>?

    public var formattedDuration: String {
        let mins = elapsedSeconds / 60
        let secs = elapsedSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public init(coordinator: SessionCoordinator) {
        self.coordinator = coordinator
        Task {
            await coordinator.addStateChangeHandler { [weak self] newState in
                Task { @MainActor [weak self] in
                    self?.handleStateChange(newState)
                }
            }
        }
    }

    private func handleStateChange(_ newState: SessionState) {
        self.state = newState
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
        let (_, gen) = await coordinator.startSession()
        self.activeGeneration = gen
        await coordinator.confirmCaptureStarted(generation: gen)
    }

    public func stopCapture() async {
        await coordinator.stopCapture(generation: activeGeneration)
    }

    public func cancel() async {
        await coordinator.cancel(generation: activeGeneration)
    }
}
