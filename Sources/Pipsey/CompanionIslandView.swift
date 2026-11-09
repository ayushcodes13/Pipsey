import SwiftUI
import PipseyCore

public struct CompanionIslandView: View {
    @ObservedObject var viewModel: IslandViewModel

    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Pipsey Mascot Avatar
            ZStack {
                Circle()
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.85))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle().stroke(mascotBorderColor, lineWidth: 2)
                    )

                Text(mascotEmoji)
                    .font(.system(size: 20))
            }

            // Main Status / Content
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

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
                }

                if viewModel.state.canCancel {
                    Button(action: {
                        Task { await viewModel.cancel() }
                    }) {
                        Text("Cancel")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
                } else if viewModel.state == .idle {
                    Button(action: {
                        Task { await viewModel.triggerSession() }
                    }) {
                        Label("Observe", systemImage: "record.circle")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.bordered)
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

@MainActor
public final class IslandViewModel: ObservableObject {
    @Published public var state: SessionState = .idle
    @Published public var explanationSummary: String? = nil

    private let coordinator: SessionCoordinator
    private var activeGeneration: Int = 0

    public init(coordinator: SessionCoordinator) {
        self.coordinator = coordinator
        Task {
            await coordinator.addStateChangeHandler { [weak self] newState in
                Task { @MainActor [weak self] in
                    self?.state = newState
                }
            }
        }
    }

    public func triggerSession() async {
        let (_, gen) = await coordinator.startSession()
        self.activeGeneration = gen
        // Confirm capture start
        await coordinator.confirmCaptureStarted(generation: gen)
    }

    public func stopCapture() async {
        await coordinator.stopCapture(generation: activeGeneration)
    }

    public func cancel() async {
        await coordinator.cancel(generation: activeGeneration)
    }
}
