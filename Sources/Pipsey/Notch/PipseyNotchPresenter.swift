import AppKit
import Foundation
import NotchKit
import PipseyCore
import SwiftUI

/// High-craft macOS Dynamic Island presenter for Pipsey, built entirely from scratch with NotchKit.
/// Manages window lifecycle, single-shape continuous morphing, physical camera cutout alignment,
/// and pointer hysteresis hover gate.
@MainActor
public final class PipseyNotchPresenter {
    public let presenter: NotchPresenter
    public let viewModel: IslandViewModel

    private var stateObservationTask: Task<Void, Never>?

    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel

        var config = NotchConfiguration.standard
        config.expandedSize = CGSize(width: 520, height: 260)
        config.collapsedWidth = .wrapCutout(reserve: 60)
        config.collapsedHitPadding = 14
        config.expandsOnHover = true
        config.hoverOpenDelay = 0.16
        config.hoverCancelGrace = 0.10
        config.collapsesOnPointerExit = true
        config.collapsesOnOutsideClick = true
        config.hapticOnHoverOpen = true
        config.expandedTopReserve = .cutoutOnly
        config.expandedTopCornerRadius = 22
        config.expandedBottomCornerRadius = 24

        let motion = NotchMotion.standard
        let style = NotchStyle.standard // Pitch-black ink to seamlessly fuse with physical hardware bezel

        self.presenter = NotchPresenter(
            configuration: config,
            motion: motion,
            style: style
        )

        installViews()
        startObservingViewModel()
    }

    private func installViews() {
        presenter.install(
            collapsed: { [weak self] in
                guard let self else { return AnyView(EmptyView()) }
                return AnyView(
                    NotchCutoutLayout(
                        cutoutWidth: self.presenter.geometry.hasPhysicalNotch
                            ? self.presenter.geometry.notchWidth : 0,
                        gutterWidth: self.presenter.collapsedGutterWidth,
                        pillHeight: self.presenter.geometry.collapsedHeight
                    ) {
                        PipseyNotchCollapsedLeadingView(viewModel: self.viewModel)
                    } trailing: {
                        PipseyNotchCollapsedTrailingView(viewModel: self.viewModel)
                    }
                )
            },
            expanded: { [weak self] in
                guard let self else { return AnyView(EmptyView()) }
                return AnyView(
                    PipseyNotchExpandedView(
                        viewModel: self.viewModel,
                        onCollapse: { [weak self] in
                            self?.presenter.collapse()
                        }
                    )
                )
            }
        )
    }

    private func startObservingViewModel() {
        // Observe state transitions to adapt expanded size and auto-expand/collapse
        stateObservationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard let self else { break }
                self.syncStateWithPresenter()
            }
        }
    }

    private var lastObservedState: SessionState = .idle

    private func syncStateWithPresenter() {
        let currentState = viewModel.state
        guard currentState != lastObservedState else { return }
        lastObservedState = currentState

        // Adapt expanded size according to active content needs
        let targetSize: CGSize
        switch currentState {
        case .idle:
            targetSize = CGSize(width: 500, height: 185)
        case .listeningAndCapturing:
            targetSize = CGSize(width: 530, height: 215)
        case .processingVisual, .generatingResponse, .starting, .stopping, .cancelling:
            targetSize = CGSize(width: 510, height: 175)
        case .readyForFollowup, .speaking:
            targetSize = CGSize(width: 550, height: 340)
        case .error:
            targetSize = CGSize(width: 510, height: 180)
        }

        if presenter.configuration.expandedSize != targetSize {
            var newConfig = presenter.configuration
            newConfig.expandedSize = targetSize
            presenter.configuration = newConfig
        }

        // Auto-expand on active session states; auto-collapse when returning to idle
        if currentState.isCapturing || currentState == .processingVisual || currentState == .generatingResponse || currentState == .speaking || currentState == .readyForFollowup {
            if presenter.phase != .expanded {
                presenter.expand(reason: .programmatic)
            }
        } else if currentState == .idle {
            // Keep expanded if hover or user click opened it, otherwise collapse
            if presenter.expandReason == .programmatic {
                presenter.collapse()
            }
        }
    }

    public func expand() {
        presenter.expand(reason: .click)
    }

    public func collapse() {
        presenter.collapse()
    }

    public func toggle() {
        presenter.toggle()
    }

    public func peek() {
        presenter.peek()
    }

    public func uninstall() {
        stateObservationTask?.cancel()
        stateObservationTask = nil
        presenter.uninstall()
    }
}
