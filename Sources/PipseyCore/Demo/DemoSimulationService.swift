import Foundation

public struct DemoScenario: Sendable {
    public let title: String
    public let appName: String
    public let appCategory: String
    public let suggestedFramework: String
    public let question: String
    public let spokenSummary: String
    public let likelyMechanism: String
    public let implementationApproach: String
    public let detailedMarkdown: String
    public let durationMs: Int64
    public let frameCount: Int

    public static let springButton = DemoScenario(
        title: "Fluid Spring Bouncy Button",
        appName: "Figma Desktop",
        appCategory: "Design & Animation",
        suggestedFramework: "SwiftUI / React Framer Motion",
        question: "How does this bouncy hover button interaction work?",
        spokenSummary: "This interaction uses an interactive spring curve. On hover, the button scales up slightly, and on mouse press it depresses with damping before bouncing back.",
        likelyMechanism: "Spring physics with response: 0.35s and dampingFraction: 0.62 combined with scaleEffect and shadow elevation.",
        implementationApproach: "Use SwiftUI's ButtonStyle protocol with .animation(.spring(response: 0.35, dampingFraction: 0.6)) applied to the makeBody configuration.",
        detailedMarkdown: """
        ```swift
        import SwiftUI

        // Realistic SwiftUI fluid spring button implementation
        struct BouncyButtonStyle: ButtonStyle {
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(hex: "0A84FF"), Color(hex: "0071E3")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    )
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                    .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
                    .shadow(
                        color: Color(hex: "0A84FF").opacity(configuration.isPressed ? 0.15 : 0.35),
                        radius: configuration.isPressed ? 4 : 12,
                        y: configuration.isPressed ? 2 : 6
                    )
                    .animation(.spring(response: 0.35, dampingFraction: 0.60), value: configuration.isPressed)
            }
        }
        ```
        """,
        durationMs: 3800,
        frameCount: 24
    )
}
