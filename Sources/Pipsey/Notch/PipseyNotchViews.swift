import AppKit
import Foundation
import NotchKit
import PipseyCore
import SwiftUI

// MARK: - Collapsed Leading Slot (Left of Cutout)

public struct PipseyNotchCollapsedLeadingView: View {
    @ObservedObject public var viewModel: IslandViewModel

    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 5) {
            switch viewModel.state {
            case .idle:
                PipseyMascotView(size: 15, isAnimated: true)
                    .frame(width: 15, height: 15)

            case .listeningAndCapturing:
                NotchBars(
                    .wave(
                        count: 3,
                        low: 0.25,
                        high: 1.0,
                        barWidth: 2.0,
                        spacing: 2.0,
                        height: 9.0,
                        period: 0.65,
                        tint: Color(hex: "2DD4BF")
                    )
                )
                .frame(height: 9)

            case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling:
                NotchBars(
                    .steady(
                        [0.35, 0.75, 0.35],
                        barWidth: 2.0,
                        spacing: 2.0,
                        height: 9.0,
                        tint: Color(hex: "2DD4BF")
                    )
                )
                .frame(height: 9)

            case .speaking:
                NotchBars(
                    .wave(
                        count: 4,
                        low: 0.2,
                        high: 1.0,
                        barWidth: 2.0,
                        spacing: 2.0,
                        height: 9.0,
                        period: 0.55,
                        tint: Color(hex: "2DD4BF")
                    )
                )
                .frame(height: 9)

            case .readyForFollowup:
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "2DD4BF"))

            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.red)
            }
        }
    }
}

// MARK: - Collapsed Trailing Slot (Right of Cutout)

public struct PipseyNotchCollapsedTrailingView: View {
    @ObservedObject public var viewModel: IslandViewModel
    @State private var recordingPulse: Bool = false

    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 5) {
            switch viewModel.state {
            case .idle:
                HStack(spacing: 4) {
                    Text("⌥⌘")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.40))
                    Circle()
                        .fill(Color(hex: "2DD4BF"))
                        .frame(width: 4, height: 4)
                        .opacity(0.85)
                }

            case .listeningAndCapturing:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 5, height: 5)
                        .opacity(recordingPulse ? 1.0 : 0.4)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: recordingPulse)
                        .onAppear { recordingPulse = true }
                    Text(viewModel.formattedDuration)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.95))
                }

            case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling:
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.65)
                    Text("Thinking")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.70))
                }

            case .speaking, .readyForFollowup:
                Text("Ready")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "2DD4BF"))

            case .error:
                Text("Error")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.9))
            }
        }
    }
}

// MARK: - Expanded Island View (Dynamic Content Panel)

public struct PipseyNotchExpandedView: View {
    @ObservedObject public var viewModel: IslandViewModel
    public var onCollapse: () -> Void

    public init(viewModel: IslandViewModel, onCollapse: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCollapse = onCollapse
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar: App Identity, Models & Quick Controls
            HStack(spacing: 8) {
                PipseyMascotView(size: 18, isAnimated: true)
                    .frame(width: 18, height: 18)

                Text("Pipsey")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white)

                // High-performance Groq Dual Model Indicator
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "2DD4BF"))
                    Text("Groq · qwen3.8-27b + gpt-oss-120b")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.60))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(Color.white.opacity(0.08)))

                Spacer()

                // State Badge Pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 5, height: 5)
                    Text(stateTitle)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(stateColor.opacity(0.18)))

                // Collapse Button
                Button(action: onCollapse) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                .buttonStyle(.plain)
                .help("Collapse to Notch")
            }

            Divider()
                .background(Color.white.opacity(0.10))

            // Body Content based on Session State
            Group {
                switch viewModel.state {
                case .idle:
                    idleView
                case .listeningAndCapturing:
                    capturingView
                case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling:
                    processingView
                case .readyForFollowup, .speaking:
                    explainingView
                case .error(let message):
                    errorView(message: message)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .foregroundStyle(Color.white)
    }

    // MARK: - State 1: Idle (Hover / Clicked from Notch)

    private var idleView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ready to observe")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text("Hold ⌥⌘ to ask aloud while demonstrating any UI on your screen.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                Spacer()

                Button {
                    Task { @MainActor in
                        await viewModel.triggerSession()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "record.circle.fill")
                            .font(.system(size: 11))
                        Text("Ask Now (⌥⌘)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: "2DD4BF")))
                    .foregroundStyle(Color.black)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Button {
                    Task { @MainActor in
                        await viewModel.runDemoSimulation()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 10.5))
                        Text("Try Demo")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .foregroundStyle(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Button {
                    HistoryWindowController.shared.showHistory()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 10.5))
                        Text("History (⌘H)")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .foregroundStyle(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Button {
                    SettingsWindowController.show()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10.5))
                        Text("Settings (⌘,)")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .foregroundStyle(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    // MARK: - State 2: Capturing & Listening

    private var capturingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Listening to verbal question...")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.90))

                Spacer()

                // Live Audio Waveform (core animation reactive)
                NotchBars(
                    .wave(
                        count: 5,
                        low: 0.15,
                        high: max(0.3, Double(viewModel.audioPowerLevel)),
                        barWidth: 2.5,
                        spacing: 2.5,
                        height: 12.0,
                        period: 0.45,
                        tint: Color(hex: "2DD4BF")
                    )
                )
                .frame(width: 25, height: 12)

                Text(viewModel.formattedDuration)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
            }

            // Real-time transcribed text
            Text(viewModel.initialQuestionInput.isEmpty ? "Speak your question aloud and interact with any app on screen..." : "“\(viewModel.initialQuestionInput)”")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(viewModel.initialQuestionInput.isEmpty ? Color.white.opacity(0.5) : Color(hex: "2DD4BF"))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))

            HStack {
                Text("Release ⌥⌘ or click Stop to synthesize answer")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.white.opacity(0.50))

                Spacer()

                Button {
                    Task { @MainActor in
                        await viewModel.cancel()
                    }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 10.5, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Button {
                    Task { @MainActor in
                        await viewModel.stopCapture()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 9))
                        Text("Stop Capture")
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4.5)
                    .background(Capsule().fill(Color.red))
                    .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - State 3: Processing

    private var processingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text(viewModel.processingStatusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.90))
                    .lineLimit(1)
                Spacer()

                Button {
                    Task { @MainActor in
                        await viewModel.cancel()
                    }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 10.5, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)
            }

            ProgressView(value: 0.6)
                .tint(Color(hex: "2DD4BF"))
        }
    }

    // MARK: - State 4: Explaining

    private var explainingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Explanation Summary Card
            if let explanation = viewModel.currentExplanation {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(explanation.spokenSummary)
                            .font(.system(size: 12.5, weight: .medium))
                            .lineSpacing(2.5)
                            .foregroundStyle(Color.white.opacity(0.95))

                        if !explanation.observedBehavior.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("OBSERVED")
                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.40))
                                Text(explanation.observedBehavior)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.70))
                            }
                            .padding(7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
                        }

                        if !explanation.likelyMechanism.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("MECHANISM")
                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(hex: "2DD4BF").opacity(0.80))
                                Text(explanation.likelyMechanism)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.75))
                            }
                            .padding(7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
                        }

                        // Follow-up Suggestions Chips
                        if !explanation.uncertainties.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SUGGESTED FOLLOW-UPS")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.45))

                                ForEach(explanation.uncertainties, id: \.self) { question in
                                    Button {
                                        Task { @MainActor in
                                            await viewModel.askFollowUp(query: question)
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "arrow.turn.down.right")
                                                .font(.system(size: 9))
                                                .foregroundStyle(Color(hex: "2DD4BF"))
                                            Text(question)
                                                .font(.system(size: 10.5))
                                                .foregroundStyle(Color.white.opacity(0.85))
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.06)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 180)
            }

            // Action Bar
            HStack(spacing: 8) {
                Button {
                    viewModel.readAloud()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.system(size: 10))
                        Text(viewModel.isSpeaking ? "Speaking..." : "Read Aloud")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .foregroundStyle(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Button {
                    if let summary = viewModel.currentExplanation?.spokenSummary {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(summary, forType: .string)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                        Text("Copy")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .foregroundStyle(Color.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    viewModel.resetToIdle()
                    onCollapse()
                } label: {
                    Text("Done")
                        .font(.system(size: 10.5, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4.5)
                        .background(Capsule().fill(Color(hex: "2DD4BF")))
                        .foregroundStyle(Color.black)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - State 5: Error

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
                Text(message)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineSpacing(2)
                    .foregroundStyle(Color.white.opacity(0.92))
            }

            HStack {
                if message.localizedCaseInsensitiveContains("screen recording") || message.localizedCaseInsensitiveContains("permission") {
                    Button {
                        PermissionCoordinator.shared.openScreenRecordingSettings()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 10))
                            Text("Open System Settings")
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(Capsule().fill(Color(hex: "2DD4BF")))
                        .foregroundStyle(Color.black)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Dismiss") {
                    viewModel.resetToIdle()
                    onCollapse()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10.5, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }
        }
    }

    private var stateTitle: String {
        switch viewModel.state {
        case .idle: return "Ready"
        case .listeningAndCapturing: return "Recording"
        case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling: return "Analyzing"
        case .speaking: return "Speaking"
        case .readyForFollowup: return "Explained"
        case .error: return "Error"
        }
    }

    private var stateColor: Color {
        switch viewModel.state {
        case .idle: return Color(hex: "2DD4BF")
        case .listeningAndCapturing: return Color.red
        case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling: return Color.orange
        case .speaking, .readyForFollowup: return Color(hex: "2DD4BF")
        case .error: return Color.red
        }
    }
}
