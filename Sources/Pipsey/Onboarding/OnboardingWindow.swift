import AppKit
import SwiftUI
import PipseyCore

public enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissions = 1
    case gesturePractice = 2
    case complete = 3
}

@MainActor
public final class OnboardingWindowController: NSWindowController, NSWindowDelegate {
    public static let shared = OnboardingWindowController()
    private var isPracticingGesture: Bool = false

    public init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 440),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        window.isMovableByWindowBackground = true
        window.level = .floating

        super.init(window: window)
        window.delegate = self
        window.contentView = NSHostingView(rootView: OnboardingView(controller: self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showOnboarding(force: Bool = false) {
        let completed = UserDefaults.standard.bool(forKey: "pipsey_has_completed_onboarding")
        let snapshot = PermissionCoordinator.shared.currentSnapshot()

        // If the user already granted Screen Recording or finished onboarding, do not popup again unless forced
        if (completed || snapshot.screenRecording == .granted) && !force {
            if !completed && snapshot.screenRecording == .granted {
                UserDefaults.standard.set(true, forKey: "pipsey_has_completed_onboarding")
            }
            return
        }

        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        AppActivationPolicy.enter()
    }

    public func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "pipsey_has_completed_onboarding")
        self.window?.close()
    }

    public func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: "pipsey_has_completed_onboarding")
        AppActivationPolicy.leave()
    }
}

public struct OnboardingView: View {
    weak var controller: OnboardingWindowController?
    @State private var currentStep: OnboardingStep = .welcome
    @State private var snapshot = PermissionCoordinator.shared.currentSnapshot()
    @State private var practiceTriggered: Bool = false
    @State private var practiceCompleted: Bool = false

    public init(controller: OnboardingWindowController?) {
        self.controller = controller
    }

    public var body: some View {
        ZStack {
            Color(hex: "0D0E12").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header / Step Indicator
                HStack(spacing: 8) {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        Capsule()
                            .fill(step.rawValue <= currentStep.rawValue ? Color.white : Color.white.opacity(0.18))
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.25), value: currentStep)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                Spacer()

                // Step Body
                Group {
                    switch currentStep {
                    case .welcome:
                        welcomeStep
                    case .permissions:
                        permissionsStep
                    case .gesturePractice:
                        gesturePracticeStep
                    case .complete:
                        completeStep
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 36)

                Spacer()

                // Footer Navigation
                HStack {
                    if currentStep != .welcome && currentStep != .complete {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                                    currentStep = prev
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    if currentStep != .complete {
                        Button(action: nextStep) {
                            HStack(spacing: 6) {
                                Text(currentStep == .welcome ? "Get Started" : "Continue")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            controller?.finishOnboarding()
                        }) {
                            Text("Start Using Pipsey")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 9)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 560, height: 440)
        .onAppear {
            snapshot = PermissionCoordinator.shared.currentSnapshot()
        }
    }

    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        }
    }

    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 16) {
            PipseyMascotView(size: 64)
                .shadow(color: Color.white.opacity(0.12), radius: 12)

            Text("Meet Pipsey")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text("Your native macOS companion that watches you interact with software and explains how it's designed and engineered.")
                .font(.system(size: 13.5))
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 420)

            HStack(spacing: 14) {
                benefitBadge(icon: "eye.fill", text: "Visual Observer")
                benefitBadge(icon: "waveform", text: "Voice Guided")
                benefitBadge(icon: "lock.fill", text: "Private & Local")
            }
            .padding(.top, 6)

            Text("Made with ❤️ by Devayush")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .padding(.top, 2)
        }
    }

    private func benefitBadge(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: "0A84FF"))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.06))
        .cornerRadius(6)
    }

    // MARK: - Step 2: Permissions
    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("System Permissions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Pipsey needs macOS access only when you actively trigger capture.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }

            VStack(spacing: 10) {
                // Microphone
                permissionRow(
                    title: "Microphone Access",
                    subtitle: "Listens to your spoken question while demonstrating.",
                    isGranted: snapshot.microphone == .authorized,
                    onAction: {
                        Task {
                            _ = await PermissionCoordinator.shared.requestMicrophoneAccess()
                            snapshot = PermissionCoordinator.shared.currentSnapshot()
                        }
                    }
                )

                // Speech Recognition
                permissionRow(
                    title: "Speech Recognition",
                    subtitle: "Transcribes questions on-device with Apple Speech.",
                    isGranted: snapshot.speechRecognition == .authorized,
                    onAction: {
                        Task {
                            _ = await PermissionCoordinator.shared.requestSpeechAccess()
                            snapshot = PermissionCoordinator.shared.currentSnapshot()
                        }
                    }
                )

                // Screen Recording
                permissionRow(
                    title: "Screen Recording",
                    subtitle: "Captures frames only when you hold ⌥⌘.",
                    isGranted: snapshot.screenRecording == .granted,
                    onAction: {
                        let granted = PermissionCoordinator.shared.requestScreenRecordingAccess()
                        if !granted {
                            PermissionCoordinator.shared.openScreenRecordingSettings()
                        }
                        snapshot = PermissionCoordinator.shared.currentSnapshot()
                    }
                )
            }

            if snapshot.screenRecording != .granted {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("After toggling Screen Recording in System Settings, click Restart Pipsey to apply.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Button("Restart Pipsey") {
                        let url = Bundle.main.bundleURL
                        let config = NSWorkspace.OpenConfiguration()
                        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
                            DispatchQueue.main.async { NSApp.terminate(nil) }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(6)
            }
        }
    }

    private func permissionRow(title: String, subtitle: String, isGranted: Bool, onAction: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if isGranted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Granted")
                        .font(.caption).bold()
                        .foregroundColor(.green)
                }
            } else {
                Button("Allow") {
                    onAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }

    // MARK: - Step 3: Gesture Practice
    private var gesturePracticeStep: some View {
        VStack(spacing: 16) {
            Text("The Capture Gesture")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text("Whenever you want to ask Pipsey how something works, simply hold **Option + Command (⌥⌘)**, ask your question, demonstrate the interaction, and release.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            // Interactive Simulator
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(practiceTriggered ? Color(hex: "0A84FF").opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(practiceTriggered ? Color(hex: "0A84FF") : Color.white.opacity(0.2), lineWidth: practiceTriggered ? 1.5 : 1.0)
                    )
                    .frame(height: 110)

                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        keyBadge(label: "⌥ Option")
                        Text("+").foregroundColor(.white.opacity(0.5))
                        keyBadge(label: "⌘ Command")
                    }

                    if practiceCompleted {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Awesome! You've got the hang of it.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    } else if practiceTriggered {
                        HStack(spacing: 6) {
                            Circle().fill(Color.red).frame(width: 8, height: 8)
                            Text("Recording Active! Now release to finish.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "0A84FF"))
                        }
                    } else {
                        Button("Simulate Gesture Practice") {
                            withAnimation {
                                practiceTriggered = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation {
                                    practiceTriggered = false
                                    practiceCompleted = true
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(Color(hex: "0A84FF"))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func keyBadge(label: String) -> some View {
        Text(label)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.12))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }

    // MARK: - Step 4: Complete
    private var completeStep: some View {
        VStack(spacing: 16) {
            PipseyMascotView(size: 56)

            Text("You're All Set!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("Pipsey lives right at the top of your screen and in the menu bar. Drag it anywhere if it ever gets in your way.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Hold ⌥⌘")
                        .font(.headline)
                        .foregroundColor(Color(hex: "0A84FF"))
                    Text("Record & Ask")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 110, height: 60)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)

                VStack(spacing: 4) {
                    Text("⌥⌘P")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Toggle Click Mode")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 110, height: 60)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)

                VStack(spacing: 4) {
                    Text("Drag Island")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Reposition Anywhere")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: 110, height: 60)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }

            Button(action: {
                controller?.finishOnboarding()
                NotificationCenter.default.post(name: NSNotification.Name("PipseyTriggerDemoSimulation"), object: nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Try Demo Simulation Now")
                }
                .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "0A84FF"))
            .foregroundColor(.black)
            .padding(.top, 4)
        }
    }
}
